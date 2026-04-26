{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

  outputs =
    { self, nixpkgs }:
    {

      nixosConfigurations.container = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (
            { pkgs, ... }:
            {
              boot.isContainer = true;
              nix.settings.experimental-features = [
                "flakes"
                "nix-command"
              ];
              nix.settings.eval-cache = true;

              # Let 'nixos-version --json' know about the Git revision
              # of this flake.
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

              # Network configuration.
              networking.useDHCP = true;
            }
          )
        ];
      };
      nixosConfigurations.sl = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (
            { pkgs, ... }:
            {
              environment.systemPackages = [ pkgs.sl ];
              boot.isContainer = true;
              nix.settings.experimental-features = [
                "flakes"
                "nix-command"
              ];

              # Let 'nixos-version --json' know about the Git revision
              # of this flake.
              system.configurationRevision = nixpkgs.lib.mkIf (self ? rev) self.rev;

              # Network configuration.
              networking.useDHCP = true;
            }
          )
        ];
      };
    };
}
