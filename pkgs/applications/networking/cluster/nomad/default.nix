{ stdenv, buildGoPackage, fetchFromGitHub, pkgs }:

buildGoPackage rec {
  name = "nomad-${version}";
  version = "0.8.6";
  rev = "v${version}";

  goPackagePath = "github.com/hashicorp/nomad";

  src = fetchFromGitHub {
    owner = "hashicorp";
    repo = "nomad";
    inherit rev;
    sha256 = "1786hbgby9q3p4x28xdc06v12n8qvxqwis70mr80axb6r4kd7yqw";
  };

  buildInputs = [ pkgs.iproute ];

  preBuild = ''
    buildFlagsArray+=("-ldflags" "-X github.com/hashicorp/nomad/version.GitDescribe=v${version} -X github.com/hashicorp/nomad/version.Version=${version} -X github.com/hashicorp/nomad/version.VersionPrerelease=")
  '';

  meta = with stdenv.lib; {
    description = "Nomad is a flexible, enterprise-grade cluster scheduler designed to easily integrate into existing workflows. Nomad can run a diverse workload of micro-service, batch, containerized and non-containerized applications.";
    homepage = https://www.nomadproject.io/;
    platforms = platforms.linux ++ platforms.darwin;
    license = licenses.mpl20;
    # TODO: Me?
    # maintainers = with maintainers; [ pradeepchhetri ];
  };
}