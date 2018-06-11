class Sherpa < Formula
  desc "Monte Carlo event generator"
  homepage "https://sherpa.hepforge.org"
  url "https://www.hepforge.org/archive/sherpa/SHERPA-MC-2.2.5.tar.gz"
  sha256 "65fd91f572f8cbbcbc17fb7c5942c2deea4a9bca8c8395551b59cafd90246167"

  option "with-mpi", "Enable MPI support"

  # Requires changes to MCFM code, so cannot use MCFM formula
  option "with-mcfm", "Enable use of MCFM loops"
  depends_on "gnu-sed" => :build if build.with? "mcfm"

  depends_on "hepmc"     => :recommended
  depends_on "rivet"     => :recommended
  depends_on "lhapdf"    => :recommended
  depends_on "fastjet"   => :recommended
  depends_on "openloops" => :recommended
  depends_on "root"      => :optional
  depends_on "open-mpi" if build.with? "mpi"
  depends_on "gcc" # for gfortran

  needs :cxx11 if build.with?("rivet") || build.with?("lhapdf")

  def install
    ENV.cxx11 if build.with?("rivet") || build.with?("lhapdf")

    ENV.delete("SDKROOT") if DevelopmentTools.clang_build_version >= 900
    args = %W[
      --disable-dependency-tracking
      --prefix=#{prefix}
      --enable-analysis
      --enable-gzip
    ]

    if build.with? "mpi"
      args << "--enable-mpi"
      ENV["CC"] = ENV["MPICC"]
      ENV["CXX"] = ENV["MPICXX"]
      ENV["FC"] = ENV["MPIFC"]
    end

    args << "--enable-hepmc2=#{Formula["hepmc"].opt_prefix}"        if build.with? "hepmc"
    args << "--enable-lhapdf=#{Formula["lhapdf"].opt_prefix}"       if build.with? "lhapdf"
    args << "--enable-fastjet=#{Formula["fastjet"].opt_prefix}"     if build.with? "fastjet"
    args << "--enable-openloops=#{Formula["openloops"].opt_prefix}" if build.with? "openloops"
    args << "--enable-root=#{Formula["root"].opt_prefix}"           if build.with? "root"
    args << "--enable-rivet=#{Formula["rivet"].opt_prefix}"         if build.with? "rivet"

    if build.with? "mcfm"
      mcfm_path = buildpath/"mcfm"
      mcfm_path.mkdir
      cd mcfm_path do
        # MCFM build sometimes fails due to race condition
        ENV.deparallelize
        # install script uses wget, remove this dependency
        inreplace "#{buildpath}/AddOns/MCFM/install_mcfm.sh", "wget", "curl -O"
        # install script uses GNU extensions to sed
        inreplace "#{buildpath}/AddOns/MCFM/install_mcfm.sh", "sed", "gsed"
        system "#{buildpath}/AddOns/MCFM/install_mcfm.sh"
        # there is no ENV.parallelize
        ENV["MAKEFLAGS"] = "-j#{ENV.make_jobs}"
        args << "--enable-mcfm=#{mcfm_path}"
      end
    end

    system "./configure", *args
    system "make", "install"

    bash_completion.install share/"SHERPA-MC/sherpa-completion"
  end

  test do
    (testpath/"Run.dat").write <<-EOS.undent
      (beam){
        BEAM_1 = 2212; BEAM_ENERGY_1 = 7000
        BEAM_2 = 2212; BEAM_ENERGY_2 = 7000
      }(beam)

      (processes){
        Process 93 93 -> 11 -11
        Order (*,2)
        Integration_Error 0.05
        End process
      }(processes)

      (selector){
        Mass 11 -11 66 166
      }(selector)

      (mi){
        MI_HANDLER = None   # None or Amisic
      }(mi)
    EOS

    system "#{bin}/Sherpa", "-p", testpath, "-L", testpath, "-e", "1000"
    ohai "You just successfully generated 1000 Drell-Yan events!"
  end
end
