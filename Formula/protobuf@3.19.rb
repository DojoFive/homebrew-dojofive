class ProtobufAT319 < Formula
  desc "Protocol buffers (Google's data interchange format)"
  homepage "https://github.com/protocolbuffers/protobuf/"
  url "https://github.com/protocolbuffers/protobuf/releases/download/v3.19.4/protobuf-all-3.19.4.tar.gz"
  sha256 "ba0650be1b169d24908eeddbe6107f011d8df0da5b1a5a4449a913b10e578faf"
  license "BSD-3-Clause"

  livecheck do
    url :stable
    strategy :github_latest
  end

  bottle do
    root_url "https://github.com/DojoFive/homebrew-dojofive/releases/download/protobuf@3.19-3.19.4"
    sha256 cellar: :any,                 monterey:     "741fa2f3563e1f657ca7c39bffc7fe2c882987443cc1f29c0c857b2aacd08999"
    sha256 cellar: :any_skip_relocation, x86_64_linux: "563575f63ab0455edc30d2aa60b51283d1151589f75c617ac25f6e914729d6ec"
  end

  head do
    url "https://github.com/protocolbuffers/protobuf.git", tag: "v3.19.4"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  depends_on "python@3.10" => [:build, :test]

  uses_from_macos "zlib"

  def install
    # Don't build in debug mode. See:
    # https://github.com/Homebrew/homebrew/issues/9279
    # https://github.com/protocolbuffers/protobuf/blob/5c24564811c08772d090305be36fae82d8f12bbe/configure.ac#L61
    ENV.prepend "CXXFLAGS", "-DNDEBUG"
    ENV.cxx11

    system "./autogen.sh" if build.head?
    system "./configure", "--disable-debug", "--disable-dependency-tracking",
                          "--prefix=#{prefix}", "--with-zlib"
    system "make"
    system "make", "check"
    system "make", "install"

    # Install editor support and examples
    pkgshare.install "editors/proto.vim", "examples"
    elisp.install "editors/protobuf-mode.el"

    ENV.append_to_cflags "-I#{include}"
    ENV.append_to_cflags "-L#{lib}"

    cd "python" do
      ["3.10"].each do |xy|
        site_packages = prefix/Language::Python.site_packages("python#{xy}")
        system "python#{xy}", *Language::Python.setup_install_args(prefix),
                              "--install-lib=#{site_packages}",
                              "--cpp_implementation"
      end
    end
  end

  test do
    testdata = <<~EOS
      syntax = "proto3";
      package test;
      message TestCase {
        string name = 4;
      }
      message Test {
        repeated TestCase case = 1;
      }
    EOS
    (testpath/"test.proto").write testdata
    system bin/"protoc", "test.proto", "--cpp_out=."
    system Formula["python@3.10"].opt_bin/"python3", "-c", "import google.protobuf"
  end
end
