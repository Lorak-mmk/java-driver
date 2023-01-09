{
  inputs = {
    nixpkgs.url = "nixpkgs";
    scylla_ccm.url = "github:Lorak-mmk/scylla-ccm/nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, scylla_ccm }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ scylla_ccm.overlays.default ]; 
        };
        jdk8 = pkgs.jdk8_headless;
        maven = pkgs.maven.override { jdk = jdk8; };
        maven_no_rc = pkgs.symlinkJoin {
          name = "maven";
          paths = [ maven ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/mvn \
              --set MAVEN_SKIP_RC 1
          '';
        };
        ccm = pkgs.scylla_ccm;
      in {
        devShell =
          pkgs.mkShell {
            buildInputs = [ jdk8 pkgs.git maven_no_rc ccm pkgs.poetry];
          };
      }
    );
}
