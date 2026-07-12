{
  description = "Development shell for agent-term.nvim";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }: {
    devShells = nixpkgs.lib.genAttrs [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell {
          packages = with pkgs; [
            ffmpeg
            imagemagick
            lua-language-server
            lua51Packages.luacheck
            neovim
            stylua
            vhs
          ];

          PLENARY_PATH = "${pkgs.vimPlugins.plenary-nvim}";
        };
      });
  };
}
