using Test
using Peacock
using LinearAlgebra

# Test homogeneous systems with known solutions
begin
    # Create homogeneous geometry
    ep = 1 + rand()
    mu = 1 + rand()
    a1 = [1,0]
    a2 = [0,1]
    d1 = d2 = 0.01
    geometry = Geometry((x,y)->ep, (x,y)->mu, a1, a2, d1, d1)
    # Check for increasing Fourier space cutoffs
    for cutoff in [1,3,5]
        # test with norm(b1) == norm(b2)
        solver = Solver(geometry, cutoff)
        for polarisation in [TE,TM]
            modes = solve(solver, [1,0], polarisation)
            @test isapprox(modes[1].frequency, 1/sqrt(ep*mu))
        end
        # test with norm(b1) != norm(b2)
        solver = Solver(geometry, cutoff, cutoff+2)
        for polarisation in [TE,TM]
            modes = solve(solver, [1,0], polarisation)
            @test isapprox(modes[1].frequency, 1/sqrt(ep*mu))
        end
    end
end


# Test conversion between real space and reciprocal space lattice vectors
a1 = rand(2)
a2 = rand(2)
b1, b2 = Peacock.as_to_bs(a1,a2)
@test isapprox(dot(a1,b1), 2pi)
@test isapprox(dot(a2,b2), 2pi)
@test isapprox(dot(a1,b2), 0, atol=1e-6)
@test isapprox(dot(a2,b1), 0, atol=1e-6)
a1_, a2_ = Peacock.bs_to_as(b1, b2)
@test isapprox(a1, a1_)
@test isapprox(a2, a2_)


# Test normalisation
data = rand(ComplexF64, 5, 5)
weighting = I + 0.5rand(ComplexF64, 5, 5)
weighting = weighting + weighting' # random positive-definite Hermitian weighting
data_ = Peacock.normalise(data, weighting=weighting)
for n in 1:size(data_,2)
    weighted_norm = sqrt(abs(dot(data_[:,n], weighting*data_[:,n])))
    @test isapprox(weighted_norm, 1)
end

# Test orthonormalisation
data_ = Peacock.orthonormalise(data, weighting=weighting)
for i in 1:size(data_,2), j in 1:size(data_,2)
    weighted_overlap = sqrt(abs(dot(data_[:,i], weighting*data_[:,j])))
    @test isapprox(weighted_overlap, float(i==j), atol=1e-6)
end
