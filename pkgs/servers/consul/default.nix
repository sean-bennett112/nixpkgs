{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "consul-${version}";
  version = "1.4.0-rc1";
  rev = "v${version}";

  goPackagePath = "github.com/hashicorp/consul";

  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = "consul";
    inherit rev;
    sha256 = "0kz7fn4jfa6wy5ykj6r7jk4qv5720l1z839v9j14kg7l6g2scm77";
  };

  preBuild = ''
    buildFlagsArray+=("-ldflags" "-X github.com/hashicorp/consul/version.GitDescribe=v${version} -X github.com/hashicorp/consul/version.Version=${version} -X github.com/hashicorp/consul/version.VersionPrerelease=")
  '';

  meta = with stdenv.lib; {
    description = "Tool for service discovery, monitoring and configuration";
    homepage = https://www.consul.io/;
    platforms = platforms.linux ++ platforms.darwin;
    license = licenses.mpl20;
    maintainers = with maintainers; [ pradeepchhetri ];
  };
}