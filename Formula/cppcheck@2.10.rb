class CppcheckAT210 < Formula
  desc "Static analysis of C and C++ code"
  homepage "https://sourceforge.net/projects/cppcheck/"
  url "https://github.com/danmar/cppcheck/archive/refs/tags/2.10.tar.gz"
  sha256 "785dcbf711048dfe43ae920b6eff2eeebb4a096e88188a40e173ca4c030f57c3"
  license "GPL-3.0-or-later"
  head "https://github.com/danmar/cppcheck.git", branch: "main"

  bottle do
    root_url "https://github.com/DojoFive/homebrew-dojofive/releases/download/cppcheck@2.10-2.10"
    sha256 x86_64_linux: "78e7776ca47217135e64e5e424c38570465301e94f19ed2574ca99a5fffc2709"
  end

  depends_on "cmake" => :build
  depends_on "python@3.11" => [:build, :test]
  depends_on "pcre"
  depends_on "tinyxml2"

  uses_from_macos "libxml2"

  def python3
    which("python3.11")
  end

  def install
    args = std_cmake_args + %W[
      -DHAVE_RULES=ON
      -DUSE_MATCHCOMPILER=ON
      -DUSE_BUNDLED_TINYXML2=OFF
      -DENABLE_OSS_FUZZ=OFF
      -DPYTHON_EXECUTABLE=#{python3}
    ]
    system "cmake", "-S", ".", "-B", "build", *args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"

    # Move the python addons to the cppcheck pkgshare folder
    (pkgshare/"addons").install Dir.glob("addons/*.py")
  end

  test do
    # Execution test with an input .cpp file
    test_cpp_file = testpath/"test.cpp"
    test_cpp_file.write <<~EOS
      #include <iostream>
      using namespace std;

      int main()
      {
        cout << "Hello World!" << endl;
        return 0;
      }

      class Example
      {
        public:
          int GetNumber() const;
          explicit Example(int initialNumber);
        private:
          int number;
      };

      Example::Example(int initialNumber)
      {
        number = initialNumber;
      }
    EOS
    system "#{bin}/cppcheck", test_cpp_file

    # Test the "out of bounds" check
    test_cpp_file_check = testpath/"testcheck.cpp"
    test_cpp_file_check.write <<~EOS
      int main()
      {
      char a[10];
      a[10] = 0;
      return 0;
      }
    EOS
    output = shell_output("#{bin}/cppcheck #{test_cpp_file_check} 2>&1")
    assert_match "out of bounds", output
  end
end
