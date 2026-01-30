{
  description = "code-server environment";

  inputs.nixpkgs.url = "https://github.com/NixOS/nixpkgs/archive/nixos-24.11.tar.gz";

  outputs = { self, nixpkgs }: let
    # 支持的架构
    systems = [ "x86_64-linux" "aarch64-linux" ];

    # 为每个系统创建包
    forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system nixpkgs.legacyPackages.${system});

    # 导入模块
    devPackages = import ./packages.nix;
    systemPackages = import ./system.nix;
    ohMyZshPackages = import ./oh-my-zsh.nix;
    vscodeExtensions = import ./vscode.nix;

  in {
    packages = forAllSystems (system: pkgs: let
      # oh-my-zsh 相关包
      ohMyZsh = ohMyZshPackages { inherit pkgs; };
      oh-my-zsh = builtins.elemAt ohMyZsh 0;
      zsh-autosuggestions = builtins.elemAt ohMyZsh 1;
      zsh-syntax-highlighting = builtins.elemAt ohMyZsh 2;

      # 合并所有工具包
      allPackages = (devPackages { inherit pkgs; })
                   ++ (systemPackages { inherit pkgs; })
                   ++ ohMyZsh;

      # 创建包含配置的环境包
      envPackage = pkgs.symlinkJoin {
        name = "code-server-env";
        paths = allPackages;
        postBuild = ''
          # 添加配置文件
          mkdir -p $out/etc
          ln -s ${vscodeExtensions { inherit pkgs; }} $out/etc/vscode-extensions.txt
          # 输出路径供 Dockerfile 使用
          echo ${oh-my-zsh} > $out/etc/oh-my-zsh.path
          echo ${zsh-autosuggestions} > $out/etc/zsh-autosuggestions.path
          echo ${zsh-syntax-highlighting} > $out/etc/zsh-syntax-highlighting.path
        '';
      };
    in {
      default = envPackage;
    });

    # 开发环境输出
    devShells = forAllSystems (system: pkgs: {
      default = pkgs.mkShell {
        buildInputs = (import ./packages.nix { inherit pkgs; })
                    ++ (import ./system.nix { inherit pkgs; });
      };
    });
  };
}
