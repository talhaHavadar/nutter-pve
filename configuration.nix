# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "nutter-pve";

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Amsterdam";

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.talha = {
    isNormalUser = true;
    initialPassword = "talha";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    packages = with pkgs; [
      tree
    ];
  };

  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    usbutils
  ];

  services.openssh.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 3493 ];
  networking.firewall.allowedUDPPorts = [ 161 ];

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  users.groups.nut.name = "nut";
  users.users.watcher = {
    group = "nut";
    isNormalUser = true;
    isSystemUser = false;
    createHome = true;
    home = "/var/lib/nut";
    hashedPassword = "$y$j9T$17hd7uG6Fy5t6eKlg76uz/$zPmSH6YLQjcYC28ebpyZQlLf8uXF6xBlBQdBbkkN9Y6";
  };
  #services.udev.extraRules = ''
  #  SUBSYSTEM=="usb", ATTRS{idVendor}=="0463", ATTRS{idProduct}=="ffff", MODE="664", GROUP="nut", OWNER="watcher"
  #'';

  # ups.status OL for online OB for on battery
  environment.etc = {
    "nut/eaton.dev" = {
      source = /home/talha/eaton.dev;
      mode = "0777";
      group = "users";
      user = "watcher";
    };
  };
  power.ups = {
    enable = true;
    mode = "netserver";
    openFirewall = true;
    users = {
      watcher = {
        passwordFile = "/home/talha/nut_user";
        upsmon = "primary";
      };
    };
    ups = {
      dummy = {
        driver = "dummy-ups";
        port = "eaton.dev";
        description = "dummy-ups dummy-once mode";
      };
    };
    upsmon = {
      enable = true;
      monitor = {
        dummy = {
          powerValue = 1;
          user = "watcher";
          type = "primary";
        };
      };
      settings = {
        MINSUPPLIES = 1;
        RUN_AS_USER = lib.mkForce "watcher";
      };
    };
    upsd = {
      enable = true;
      listen = [
        {
          address = "0.0.0.0";
          port = 3493;
        }
        {
          address = "127.0.0.1";
          port = 3493;
        }
      ];
    };
  };
  services.apcupsd = {
    enable = true;
    configText = ''
      UPSTYPE usb
      DEVICE
      BATTERYLEVEL 5
      MINUTES 5
      ONBATTERYDELAY 30
      NISIP 127.0.0.1
      NISPORT 3551
    '';
    hooks = {
      onbattery = ''
        echo "UPS is on battery!!"
        now="$(date -Iseconds)"
        echo "$now" >> /home/talha/upsbattery.log
        sed -i "s/ups.status:.*/ups.status: OB/" /etc/nut/eaton.dev
        exit 99
      '';
      mainsback = ''
        echo "UPS is on main power!!"
        now="$(date -Iseconds)"
        echo "$now" >> /home/talha/upsmains.log
        sed -i "s/ups.status:.*/ups.status: OL/" /etc/nut/eaton.dev
        exit 99
      '';
    };
  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}

