{config, lib, ...}: {
  project = {
    name = "stump";
    summary = "Nix packaging for the STUMP USENET robomoderator";
    ## This defaults to `true`, because I want most projects to be
    ## contributable-to by non-Nix users. However, Nix-specific projects can
    ## lean into Project Manager and avoid committing extra files.
    commit-by-default = lib.mkForce false;
  };

  ## dependency management
  services.renovate.enable = true;

  ## development
  programs = {
    direnv = {
      enable = true;
      ## See the reasoning on `project.commit-by-default`.
      commit-envrc = false;
    };
    # This should default by whether there is a .git file/dir (and whether it’s
    # a file (worktree) or dir determines other things – like where hooks
    # are installed.
    git.enable = true;
  };

  ## formatting
  editorconfig.enable = true;
  programs = {
    treefmt.enable = true;
    vale = {
      enable = true;
      excludes = [
        "./.github/settings.yml"
      ];
      vocab.${config.project.name}.accept = [
        "formatter"
      ];
    };
  };

  ## CI
  services.garnix = {
    enable = true;
    builds.exclude = [
      # TODO: Remove once garnix-io/garnix#285 is fixed.
      "homeConfigurations.x86_64-darwin-example"
    ];
  };

  ## publishing
  services = {
    flakehub.enable = true;
    github = {
      enable = true;
      settings.repository.topics = ["usenet" "moderation"];
    };
  };
}
