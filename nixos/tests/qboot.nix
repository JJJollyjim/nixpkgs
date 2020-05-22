import ./make-test-python.nix ({ pkgs, ...} : {
  name = "qboot";

  machine = { ... }: {
    virtualisation.useQBoot = true;
  };

  testScript =
    ''
      start_all()
      machine.wait_for_unit("multi-user.target")
      machine.shutdown()
    '';
})
