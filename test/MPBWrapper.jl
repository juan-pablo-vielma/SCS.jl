@testset "Test the MathProgBase wrapper with linprog" begin
    include("mpb_linear.jl")
end

using Compat.Pkg: dir
for T in [SCS.Direct, SCS.Indirect]
    @testset "MathProgBase $T" begin
        include(joinpath(dir("MathProgBase"),"test","conicinterface.jl"))
        coniclineartest(SCS.SCSSolver(linear_solver=T, eps=1e-6, verbose=0),
                        duals=true, tol=1e-5)
        conicSOCtest(SCS.SCSSolver(linear_solver=T, verbose=0),
                     duals=true, tol=1e-5)
        conicEXPtest(SCS.SCSSolver(linear_solver=T, eps=1e-6, verbose=0),
                     duals=true, tol=1e-5)
        conicSDPtest(SCS.SCSSolver(linear_solver=T, eps=1e-6, verbose=0),
                     duals=true, tol=1e-5)
    end
end
