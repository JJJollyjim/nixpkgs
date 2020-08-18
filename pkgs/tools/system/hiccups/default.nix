{ stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  pname = "hiccups";
  version = "unstable-2020-03-26";

  src = fetchFromGitHub {
    owner = "rigtorp";
    repo  = "hiccups";
    rev = "cf7d2887bcfc023247e4dcf1fd8eddf0817f3eb8";
    sha256 = "111fs7ikcmkwpy4mdip8cd4bmy68acrg1giaxjj17j70mr9iwk5q";
  };

  cmakeFlags = [
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ ];

  meta = with stdenv.lib; {
    description = "Tool to measure system induced jitter (\"hiccups\") a CPU-bound thread experiences";
    homepage = "https://github.com/rigtorp/hiccups";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = with maintainers; [ jjjollyjim ];
  };
}
