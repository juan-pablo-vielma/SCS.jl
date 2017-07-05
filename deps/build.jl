using BinDeps

@BinDeps.setup

blasvendor = Base.BLAS.vendor()

libnames = ["libscsdir", "libscsindir"]

if (is_apple() ? (blasvendor == :openblas64) : false)
    libnames = [libname*"64" for libname in libnames]
end

scs = library_dependency("scs", aliases=[libnames[1]])
scsindir = library_dependency("scsindir", aliases=[libnames[2]])

if is_apple()
    using Homebrew
    provides(Homebrew.HB, "scs", scs, os = :Darwin)
end

version = "1.2.6"
win_version = "1.1.5"

provides(Sources, URI("https://github.com/cvxgrp/scs/archive/v$version.tar.gz"),
    [scs], os=:Unix, unpacked_dir="scs-$version")

# Windows binaries built in Cygwin as follows:
# CFLAGS="-DDLONG -DCOPYAMATRIX -DLAPACK_LIB_FOUND -DCTRLC=1 -DBLAS64 -DBLASSUFFIX=_64_" LDFLAGS="-L$HOME/julia/usr/bin -lopenblas64_" make CC=x86_64-w64-mingw32-gcc out/libscsdir.dll
# mv out bin64
# make clean
# CFLAGS="-DDLONG -DCOPYAMATRIX -DLAPACK_LIB_FOUND -DCTRLC=1" LDFLAGS="-L$HOME/julia32/usr/bin -lopenblas" make CC=i686-w64-mingw32-gcc out/libscsdir.dll
# mv out bin32
provides(Binaries, URI("https://cache.julialang.org/https://bintray.com/artifact/download/tkelman/generic/scs-$win_version-r2.7z"),
    [scs], unpacked_dir="bin$(Sys.WORD_SIZE)", os = :Windows,
    SHA="62bb4feeb7d2cd3db595f05b86a20fc93cfdef23311e2e898e18168189072d02")

prefix = joinpath(BinDeps.depsdir(scs), "usr")
srcdir = joinpath(BinDeps.depsdir(scs), "src", "scs-$version/")

ldflags = ""

if is_apple()
    ldflags = "$ldflags -undefined suppress -flat_namespace"
end

cflags = "-DCOPYAMATRIX -DDLONG -DLAPACK_LIB_FOUND -DCTRLC=1"

if blasvendor == :openblas64
    cflags = "$cflags -DBLAS64 -DBLASSUFFIX=_64_"
elseif blasvendor == :mkl
    if Base.USE_BLAS64
        cflags = "$cflags -DMKL_ILP64 -DBLAS64"
        ldflags = "$ldflags -lmkl_intel_ilp64"
    else
        ldflags = "$ldflags -lmkl_intel"
    end
    ldflags = "$ldflags -lmkl_gnu_thread -lmkl_rt -lmkl_core"
end

cflags = "$cflags -fopenmp"
ldflags = "$ldflags -lgomp"

ENV2 = copy(ENV)
ENV2["LDFLAGS"] = ldflags
ENV2["CFLAGS"] = cflags

libnames_full = [libname*".$(Libdl.dlext)" for libname in libnames]

provides(SimpleBuild,
    (@build_steps begin
        GetSources(scs)
        CreateDirectory(joinpath(prefix, "lib"))
        FileRule(joinpath(prefix, "lib", libnames_full[1]),
            @build_steps begin
                ChangeDirectory(srcdir)
                setenv(`make out/$(libnames_full[1])`, ENV2)
                `mv out/$(libnames_full[1]) $prefix/lib`
            end)
        FileRule(joinpath(prefix, "lib", libnames_full[2]),
            @build_steps begin
                ChangeDirectory(srcdir)
                setenv(`make out/$(libnames_full[2])`, ENV2)
                `mv out/$(libnames_full[2]) $prefix/lib`
            end)
    end),
    [scs, scsindir], os=:Unix)

@BinDeps.install Dict(:scs => :scs, :scsindir => :scsindir)
