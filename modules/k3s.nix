{...}: {
  services.k3s = {
    enable = true;
    clusterInit = true;
  };
}
