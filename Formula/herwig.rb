class Herwig < Formula
  desc "Monte Carlo event generator"
  homepage "https://herwig.hepforge.org"
  url "https://www.hepforge.org/archive/herwig/Herwig-7.1.1.tar.bz2"
  sha256 "72980712a209ae242e7a2c71653683bd8dfe7d339f0b1197b8d5f493f9f4aa8f"

  head do
    url "http://herwig.hepforge.org/hg/herwig", :using => :hg

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
    depends_on "gengetopt"
  end

  option "with-test", "Test during installation"

  depends_on "thepeg"
  depends_on "hepmc"
  depends_on "boost"
  depends_on "gsl"
  depends_on "madgraph5_amcatnlo" => :optional
  depends_on "openloops" => :optional
  depends_on "vbfnlo" => :optional
  depends_on "gcc" # for gfortran
  cxxstdlib_check :skip

  def download_pdfs(dest, pdfs)
    pdfs.each { |pdf| quiet_system "lhapdf", "--pdfdir=#{dest}", "install", pdf }
    ENV["LHAPDF_DATA_PATH"] = dest
  end

  def install
    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
      --with-thepeg=#{Formula["thepeg"].opt_prefix}
      --enable-stdcxx11
    ]

    args << "--with-madgraph=#{Formula["madgraph5_amcatnlo"].opt_prefix}" if build.with? "madgraph5_amcatnlo"
    args << "--with-openloops=#{Formula["openloops"].opt_prefix}"         if build.with? "openloops"
    args << "--with-vbfnlo=#{Formula["vbfnlo"].opt_prefix}"               if build.with? "vbfnlo"

    # Herwig runs ThePEG during the make install and make check phases
    download_pdfs(buildpath/"pdf-sets", %w[MMHT2014lo68cl MMHT2014nlo68cl])

    system "autoreconf", "-i" if build.head?
    system "./configure", *args
    system "make"
    system "make", "check" if build.with? "test"
    system "make", "install"
  end

  test do
    download_pdfs(testpath/"pdf-sets", %w[MMHT2014lo68cl MMHT2014nlo68cl])

    system "#{bin}/Herwig", "read", share/"Herwig/LHC.in"
    system "#{bin}/Herwig", "run", "LHC.run", "-N", "50"
    ohai "Successfully generated 50 LHC Drell-Yan events."
  end
end
