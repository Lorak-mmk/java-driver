{
  inputs = {
    nixpkgs.url = "nixpkgs";
    scylla_ccm.url = "github:Lorak-mmk/scylla-ccm/nix";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, scylla_ccm }:
    let
      ld_library_path = pkgs: pkgs.lib.makeLibraryPath [ pkgs.stdenv.cc.libc pkgs.libxcrypt-legacy ];
      # https://fzakaria.com/2020/11/12/debugging-a-jnr-ffi-bug-in-nix.html
      jdk_with_library_path = jdk: name: pkgs: pkgs.symlinkJoin {
        inherit name;
        paths = [ jdk ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/java \
            --set LD_LIBRARY_PATH ${ld_library_path pkgs} \
            --set JAVA_TOOL_OPTIONS -Djava.library.path=${ld_library_path pkgs}
          
          wrapProgram $out/bin/javac \
            --set LD_LIBRARY_PATH ${ld_library_path pkgs} \
            --set JAVA_TOOL_OPTIONS -Djava.library.path=${ld_library_path pkgs}
        '';
      };
      prepare_mvn = jdk: bin_name: pkgs:
        let mvn = pkgs.maven.override { jdk = jdk; }; in
          pkgs.writeShellScriptBin "${bin_name}" ''
            export MAVEN_SKIP_RC=1
            exec -a mvn ${mvn}/bin/mvn "$@"
          '';
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ scylla_ccm.overlays.default ]; 
        };
        jdk8 = jdk_with_library_path pkgs.jdk8_headless "jdk8_wrapped" pkgs;
        jdk11 = jdk_with_library_path pkgs.jdk11_headless "jdk11_wrapped" pkgs;
        jdk17 = jdk_with_library_path pkgs.jdk17_headless "jdk17_wrapped" pkgs;
        mvn8 = prepare_mvn jdk8 "mvn8" pkgs;
        mvn11 = prepare_mvn jdk11 "mvn11" pkgs;
        mvn17 = prepare_mvn jdk17 "mvn17" pkgs;
        ccm = pkgs.scylla_ccm pkgs.python311;
      in {
        devShell =
          pkgs.mkShell {
            buildInputs = [ pkgs.git mvn8 mvn11 mvn17 jdk11 ccm pkgs.poetry];
            shellHook = ''
              unset JAVA_HOME
            '';
          };
      }
    );
}
