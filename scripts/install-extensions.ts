import { Buffer } from 'node:buffer'
import { mkdir, readdir, rename, rm, writeFile } from 'node:fs/promises'
import path from 'node:path'
import process from 'node:process'

const VSIX_FILE_NAME_REGEX = /^(?<extensionId>.+)-(?<version>\d[0-9A-Z.+-]*)\.vsix$/i

const EXTENSIONS_DIR = path.resolve(process.cwd(), process.env.EXTENSIONS_DIR || path.join('.cache', 'extensions'))
const MARKETPLACE_API_URL = 'https://marketplace.visualstudio.com/_apis/public/gallery/extensionquery?api-version=3.0-preview.1'
const MARKETPLACE_QUERY_FLAGS = 103

const MANAGED_EXTENSIONS = [
  'antfu.iconify',
  'antfu.icons-carbon',
  'antfu.open-in-github-button',
  'antfu.theme-vitesse',
  'antfu.unocss',
  'dbaeumer.vscode-eslint',
  'johnsoncodehk.vscode-tsconfig-helper',
  'ms-vscode.vscode-typescript-next',
  'usernamehw.errorlens',
  'vue.volar',
  'yoavbls.pretty-ts-errors'
] as const

type ManagedExtensionId = (typeof MANAGED_EXTENSIONS)[number]

interface LocalVsixFile {
  extensionId: string
  fileName: string
  filePath: string
  version: string
}

interface GalleryFile {
  assetType: string
  source: string
}

interface GalleryVersion {
  assetUri?: string
  fallbackAssetUri?: string
  files?: GalleryFile[]
  lastUpdated?: string
  targetPlatform?: string
  version: string
}

interface GalleryExtension {
  displayName?: string
  extensionName: string
  publisher?: {
    publisherName?: string
  }
  versions: GalleryVersion[]
}

interface ExtensionQueryResponse {
  results?: Array<{
    extensions?: GalleryExtension[]
  }>
}

type UpdateOutcome
  = | { extensionId: string, status: 'up-to-date', version: string }
    | { extensionId: string, status: 'downloaded', version: string }
    | { extensionId: string, status: 'failed', reason: string }

function parseVsixFileName(fileName: string): LocalVsixFile | null {
  const match = VSIX_FILE_NAME_REGEX.exec(fileName)

  if (!match?.groups) {
    return null
  }

  return {
    extensionId: match.groups.extensionId,
    fileName,
    filePath: path.join(EXTENSIONS_DIR, fileName),
    version: match.groups.version
  }
}

async function scanLocalVsixFiles(): Promise<Map<string, LocalVsixFile[]>> {
  await mkdir(EXTENSIONS_DIR, { recursive: true })

  const files = await readdir(EXTENSIONS_DIR, { withFileTypes: true })
  const byExtensionId = new Map<string, LocalVsixFile[]>()

  for (const entry of files) {
    if (!entry.isFile() || !entry.name.endsWith('.vsix')) {
      continue
    }

    const parsed = parseVsixFileName(entry.name)

    if (!parsed) {
      console.warn(`[warn] Skip unrecognized VSIX file name: ${entry.name}`)
      continue
    }

    const items = byExtensionId.get(parsed.extensionId) ?? []
    items.push(parsed)
    byExtensionId.set(parsed.extensionId, items)
  }

  return byExtensionId
}

async function queryMarketplace(extensionId: string): Promise<GalleryExtension> {
  const response = await fetch(MARKETPLACE_API_URL, {
    method: 'POST',
    headers: {
      'accept': 'application/json;api-version=3.0-preview.1;excludeUrls=false',
      'content-type': 'application/json',
      'user-agent': 'code-server-extension-updater',
      'x-market-client-id': 'code-server-extension-updater'
    },
    body: JSON.stringify({
      filters: [
        {
          criteria: [
            {
              filterType: 7,
              value: extensionId
            }
          ],
          direction: 2,
          pageNumber: 1,
          pageSize: 1,
          sortBy: 0,
          sortOrder: 0
        }
      ],
      assetTypes: [],
      flags: MARKETPLACE_QUERY_FLAGS
    })
  })

  if (!response.ok) {
    throw new Error(`Marketplace query failed with HTTP ${response.status}`)
  }

  const payload = (await response.json()) as ExtensionQueryResponse
  const extension = payload.results?.[0]?.extensions?.[0]

  if (!extension) {
    throw new Error('Extension not found in Marketplace')
  }

  return extension
}

function pickLatestVersion(extension: GalleryExtension): GalleryVersion {
  const stableVersion = extension.versions.find(version => version.targetPlatform === 'undefined' || version.targetPlatform === undefined)
  const latestVersion = stableVersion ?? extension.versions[0]

  if (!latestVersion) {
    throw new Error('Marketplace returned no versions')
  }

  return latestVersion
}

function getVsixDownloadUrl(version: GalleryVersion): string {
  const packageFile = version.files?.find(file => file.assetType === 'Microsoft.VisualStudio.Services.VSIXPackage')

  if (packageFile?.source) {
    return packageFile.source
  }

  if (version.assetUri) {
    return `${version.assetUri}/Microsoft.VisualStudio.Services.VSIXPackage`
  }

  if (version.fallbackAssetUri) {
    return `${version.fallbackAssetUri}/Microsoft.VisualStudio.Services.VSIXPackage`
  }

  throw new Error('Marketplace returned no VSIX download URL')
}

async function downloadVsixFile(extensionId: string, version: string, downloadUrl: string): Promise<string> {
  const fileName = `${extensionId}-${version}.vsix`
  const destinationPath = path.join(EXTENSIONS_DIR, fileName)
  const temporaryPath = `${destinationPath}.download`
  const response = await fetch(downloadUrl, {
    headers: {
      'user-agent': 'code-server-extension-updater'
    },
    redirect: 'follow'
  })

  if (!response.ok) {
    throw new Error(`Download failed with HTTP ${response.status}`)
  }

  const content = Buffer.from(await response.arrayBuffer())
  await writeFile(temporaryPath, content)
  await rename(temporaryPath, destinationPath)

  return destinationPath
}

async function removeOutdatedFiles(extensionId: string, keepVersion: string, localFiles: LocalVsixFile[]): Promise<void> {
  const removals = localFiles
    .filter(file => file.version !== keepVersion)
    .map(file => rm(file.filePath, { force: true }))

  await Promise.all(removals)
}

async function updateExtension(extensionId: ManagedExtensionId, localFiles: LocalVsixFile[]): Promise<UpdateOutcome> {
  try {
    const extension = await queryMarketplace(extensionId)
    const latestVersion = pickLatestVersion(extension)
    const localVersion = localFiles.find(file => file.version === latestVersion.version)

    if (localVersion) {
      await removeOutdatedFiles(extensionId, latestVersion.version, localFiles)
      return {
        extensionId,
        status: 'up-to-date',
        version: latestVersion.version
      }
    }

    const downloadUrl = getVsixDownloadUrl(latestVersion)
    await downloadVsixFile(extensionId, latestVersion.version, downloadUrl)
    await removeOutdatedFiles(extensionId, latestVersion.version, localFiles)

    return {
      extensionId,
      status: 'downloaded',
      version: latestVersion.version
    }
  }
  catch (error) {
    return {
      extensionId,
      status: 'failed',
      reason: error instanceof Error ? error.message : String(error)
    }
  }
}

function logManagedExtensionDrift(localFilesByExtensionId: Map<string, LocalVsixFile[]>): void {
  const managedIds = new Set<string>(MANAGED_EXTENSIONS)
  const unmanagedIds = [...localFilesByExtensionId.keys()].filter(extensionId => !managedIds.has(extensionId))

  if (unmanagedIds.length === 0) {
    return
  }

  console.warn(`[warn] Found unmanaged local VSIX files: ${unmanagedIds.join(', ')}`)
  console.warn('[warn] Add them to MANAGED_EXTENSIONS if they should keep receiving updates.')
}

async function main(): Promise<void> {
  console.log(`[info] Output directory: ${EXTENSIONS_DIR}`)

  const localFilesByExtensionId = await scanLocalVsixFiles()
  logManagedExtensionDrift(localFilesByExtensionId)

  const results: UpdateOutcome[] = []

  for (const extensionId of MANAGED_EXTENSIONS) {
    const localFiles = localFilesByExtensionId.get(extensionId) ?? []
    const currentVersions = localFiles.map(file => file.version).join(', ') || 'none'

    console.log(`[info] Checking ${extensionId} (local: ${currentVersions})`)
    const result = await updateExtension(extensionId, localFiles)
    results.push(result)

    if (result.status === 'downloaded') {
      console.log(`[done] Downloaded ${extensionId}@${result.version}`)
      continue
    }

    if (result.status === 'up-to-date') {
      console.log(`[skip] ${extensionId} already at ${result.version}`)
      continue
    }

    console.error(`[fail] ${extensionId}: ${result.reason}`)
  }

  const failedCount = results.filter(result => result.status === 'failed').length
  const downloadedCount = results.filter(result => result.status === 'downloaded').length
  const skippedCount = results.filter(result => result.status === 'up-to-date').length

  console.log(`\nSummary: ${downloadedCount} downloaded, ${skippedCount} skipped, ${failedCount} failed.`)

  if (failedCount > 0) {
    process.exitCode = 1
  }
}

main().catch((error: unknown) => {
  console.error('[fatal]', error)
  process.exitCode = 1
})
