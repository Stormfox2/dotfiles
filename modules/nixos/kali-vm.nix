{
  config,
  lib,
  pkgs,
  inputs,
  user,
  ...
}:
let
  kaliImage = pkgs.stdenvNoCC.mkDerivation {
    pname = "kali-linux-cloud";
    version = "2025.4";
    src = pkgs.fetchurl {
      url = "https://kali.download/cloud-images/current/kali-linux-2025.4-cloud-genericcloud-amd64.tar.xz";
      # Update with: ./update-kali-vm.sh
      sha256 = "13zy721lwa4z2ymdjm6mypbrisx5c296la7slp0288rzf2j217v4";
    };

    nativeBuildInputs = [
      pkgs.xz
      pkgs.gnutar
    ];

    # Pure unpack in the Nix builder sandbox
    unpackPhase = "true"; # we'll do it ourselves in buildPhase
    buildPhase = ''
      mkdir extracted
      tar -xJf "$src" -C extracted
      img=$(find extracted -type f -name '*.raw' | head -n1)
      if [ -z "$img" ]; then
        echo "No raw found in $src" >&2
        exit 1
      fi
      # Copy to $out (must be a single file, not a directory)
      ${pkgs.qemu}/bin/qemu-img convert -f raw -O qcow2 "$img" $out
    '';

    installPhase = "true"; # nothing more to install
    dontFixup = true;
  };

  flakeArchive = pkgs.runCommand "flake-archive.tgz" { } ''
    tar -czf $out -C ${/path/to/your/flake} . --exclude .git
  '';

  cloudInitISO = pkgs.runCommand "kali-cloudinit.iso" { buildInputs = [ pkgs.genisoimage ]; } ''
        mkdir -p cloudinit
        cat > cloudinit/meta-data <<EOF
    instance-id: kali-vm
    local-hostname: kali-vm
    EOF
        cat > cloudinit/user-data <<EOF
    #cloud-config
    preserve_hostname: false
    hostname: kali-vm
    users:
      - name: pentest
        gecos: "Pentest User"
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: users,sudo
        shell: /bin/bash
        lock_passwd: false
        plain_text_passwd: "pentest"

    package_update: true
    packages: [ "curl", "xz-utils", "ca-certificates", "sudo", "unzip" ]

    runcmd:
      - [ bash, -lc, 'apt-get update -y && apt-get install -y curl xz-utils ca-certificates sudo' ]
      - [ bash, -lc, 'sh <(curl -L https://nixos.org/nix/install) --daemon' ]
      - [ bash, -lc, 'mkdir -p /etc/nix; echo "experimental-features = nix-command flakes" > /etc/nix/nix.conf' ]
      - [ bash, -lc, 'sudo -iu pentest bash -lc "mkdir -p ~/dotfiles && tar xzf /var/lib/cloud/seed/nocloud/flake.tgz -C ~/dotfiles"' ]
      - [ bash, -lc, 'sudo -iu pentest bash -lc "cd ~/dotfiles && nix run ./#homeConfigurations.pentest.activationPackage --show-trace || echo activation failed"' ]
      - [ bash, -lc, 'rm -rf /var/lib/cloud/seed/nocloud /var/lib/cloud/* /home/pentest/.bash_history /root/.bash_history /home/pentest/.git* || true' ]
    EOF
        cp ${flakeArchive} cloudinit/flake.tgz
        genisoimage -output $out -volid cidata -joliet -rock cloudinit
  '';
in
{
  config = {
    users.groups.libvirtd.members = [ user ];

    programs.virt-manager.enable = true;

    system.activationScripts.kali-vm-image = ''
      install -Dm644 ${kaliImage} /var/lib/libvirt/images/kali-vm.qcow2
      chown qemu-libvirtd:qemu-libvirtd /var/lib/libvirt/images/kali-vm.qcow2
    '';

    virtualisation = {
      libvirtd = {
        enable = true;
        qemu = {
          # allow running as your user (not just root)
          runAsRoot = false;
          swtpm.enable = true; # optional, enables TPM emulation
        };
      };

      # Define connection. For system-wide VMs:
      libvirt = {
        enable = true;
        connections."qemu:///system" = {
          domains = [
            {
              definition = inputs.nixvirt.lib.domain.writeXML (
                inputs.nixvirt.lib.domain.templates.linux {
                  name = "kali-vm";
                  uuid = "cc7439ed-36af-4696-a6f2-1f0c4474d87e";
                  memory = {
                    count = 6;
                    unit = "GiB";
                  };
                  storage_vol = "/var/lib/libvirt/images/kali-vm.qcow2";
                  # install_vol = "${cloudInitISO}";
                }
              );
            }
          ];
          networks = [
            {
              definition = inputs.nixvirt.lib.network.writeXML (
                inputs.nixvirt.lib.network.templates.bridge {
                  uuid = "70b08691-28dc-4b47-90a1-45bbeac9ab5a";
                  subnet_byte = 71;
                }
              );
              active = true;
            }
          ];
        };
      };
    };
  };
}
