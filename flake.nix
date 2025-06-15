{
  inputs = {
    nixpkgs.url = "github:cachix/devenv-nixpkgs/rolling";
    systems.url = "github:nix-systems/default";
    devenv.url = "github:cachix/devenv";
    devenv.inputs.nixpkgs.follows = "nixpkgs";

    nixCats = {
      url = "github:Hier0nim/nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  nixConfig = {
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  outputs =
    {
      self,
      nixpkgs,
      devenv,
      systems,
      nixCats,
      ...
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      packages = forEachSystem (system: {
        devenv-up = self.devShells.${system}.default.config.procfileScript;
        devenv-test = self.devShells.${system}.default.config.test;
      });

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = devenv.lib.mkShell {
            inherit inputs pkgs;
            modules = [
              {
                # https://devenv.sh/reference/options/

                packages =
                  [
                    pkgs.hello
                    nixCats.packages.${system}.nvim-python

                    # jetbrains.pycharm-community-bin
                    # (pkgs.writeShellScriptBin "pycharm" ''
                    #   #!/usr/bin/env bash
                    #   exec "${pkgs.jetbrains.pycharm-community-bin}/bin/pycharm-community" "$@"
                    # '')
                  ]
                  ++ (with pkgs.python3Packages; [
                    pandas
                    numpy
                    scikit-learn
                    scipy
                    matplotlib
                    seaborn
                    joblib
                    graphviz

                    # required by molten-nvim
                    ipykernel
                    pynvim
                    jupyter-client
                    cairosvg # for image rendering
                    pnglatex # for image rendering
                    plotly # for image rendering
                    pyperclip
                    nbformat
                    # jupytext
                    # ipykernel
                    # ipython
                    # jupyter
                    # jupyterlab
                  ]);

                languages.python = {
                  enable = true;
                  package = pkgs.python3;
                  venv = {
                    enable = true;
                    # requirements = ./requirements.txt;
                  };
                };

                enterShell = ''
                  python -m ipykernel install --user --name python3 --display-name "Python ⟨devenv⟩"
                '';
              }
            ];
          };
        }
      );
    };
}
