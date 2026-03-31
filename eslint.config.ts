import antfu from '@antfu/eslint-config'

export default antfu(
  {
    rules: {
      'style/comma-dangle': ['warn', 'never']
    }
  },
  {
    files: ['**/*.vue'],
    rules: {
      'vue/block-order': ['error', {
        order: ['style', 'template', 'script']
      }],
      'vue/comma-dangle': ['warn', 'never']
    }
  },
  {
    files: ['**/*.json', '**/*.jsonc'],
    rules: {
      'jsonc/comma-dangle': ['warn', 'never']
    }
  }
)
