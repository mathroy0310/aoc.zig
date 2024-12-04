{
  inputs = rec {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    zig-overlay.url = "github:mitchellh/zig-overlay";
  };
  outputs = inputs @ {
    self,
    nixpkgs,
    ...
  }:
  let
    pkgs = nixpkgs.legacyPackages.x86_64-linux;
    zig = inputs.zig-overlay.packages.x86_64-linux.master;
  in
  {
    devShells.x86_64-linux.default = pkgs.mkShell {
      packages = with pkgs; [
        zls
        zig

        # Also need curl for the AoC input fetching script
        curl
      ];
      shellHook = ''
        echo "Using Zig version: $(zig version)"
        echo "Using ZLS version: $(zls --version || echo 'ZLS not set up correctly')"
        echo "Using curl version: $(curl --version | head -n 1 | awk '{print $2}')"
        code .
      '';
    };
  };
}