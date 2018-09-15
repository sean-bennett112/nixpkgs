# NOTE: buildGo110Package is only because I'm currently on 18.03.
#       this has been updated in master.
{ stdenv, buildGoPackage, fetchFromGitHub }:

buildGoPackage rec {
  name = "consul-${version}";
  version = "1.2.3";
  rev = "v${version}";

  goPackagePath = "github.com/hashicorp/consul";

  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = "consul";
    inherit rev;
    sha256 = "1lyq52qxawk9zkc61rnvqiyk5syrqckrgavzbqqdxj0qp3ljy5wp";
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