{ ... }:
{
  sops.secrets.notes-git-crypt-key = {
    sopsFile = ../../secrets/notes-git-crypt.key;
    format = "binary";
    owner = "matt";
  };
}
