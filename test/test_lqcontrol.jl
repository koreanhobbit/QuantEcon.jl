module TestLQcontrol

using QuantEcon
using Base.Test
using FactCheck
using Compat

rough_kwargs = @compat Dict(:atol => 1e-13, :rtol => 1e-4)

# set up
q    = 1.
r    = 1.
rf   = 1.
a    = .95
b    = -1.
c    = .05
β    = .95
n    = 0.
capT = 1
lq_scalar = LQ(q, r, a, b, c, n, β, capT, rf)

Q  = [0. 0.; 0. 1]
R  = [1. 0.; 0. 0]
rf = eye(2) .* 100
A  = fill(0.95, 2, 2)
B  = fill(-1.0, 2, 2)
lq_mat = LQ(Q, R, A, B, bet=β, capT=capT, rf=rf)

facts("Testing lqcontrol.jl") do
    context("Test scalar sequences with exact by hand solution") do
        x0 = 2.0
        x_seq, u_seq, w_seq = compute_sequence(lq_scalar, x0)
        # solve by hand
        u_0 = (-2.*lq_scalar.A*lq_scalar.B*lq_scalar.bet*lq_scalar.rf) /
           (2.*lq_scalar.Q+lq_scalar.bet*lq_scalar.rf*2lq_scalar.B^2)*x0
        x_1 = lq_scalar.A * x0 + lq_scalar.B * u_0 + w_seq[end]

        @fact u_0[1] => roughly(u_seq[end]; rough_kwargs...)
        @fact x_1[1] => roughly(x_seq[end]; rough_kwargs...)
    end

    context("test matrix solutions") do
        x0 = randn(2) * 25
        x_seq, u_seq, w_seq = compute_sequence(lq_mat, x0)

        @fact sum(u_seq) => roughly(0.95 * sum(x0); rough_kwargs...)
        @fact x_seq[:,end] => roughly(zeros(x0); rough_kwargs...)
    end

    context("test stationary matrix") do
        x0 = randn(2) .* 25
        P, F, d = stationary_values(lq_mat)

        f_answer = [-.95 -.95; 0. 0.]
        p_answer = [1. 0; 0. 0.]

        val_func_lq = (x0' * P * x0)[1]
        val_func_answer = x0[1]^2

        @fact f_answer => roughly(F; rough_kwargs...)
        @fact val_func_lq => roughly(val_func_answer; rough_kwargs...)
        @fact p_answer => roughly(P; rough_kwargs...)
    end

    context("test runs a (n,k,j) = (2,1,1) model") do
        # == Model parameters == #
        r = 0.05
        bet = 1 / (1 + r)
        T = 45
        c_bar = 2.0
        sigma = 0.25
        mu = 1.0
        q = 1e6

        # == Formulate as an LQ problem == #
        Q = 1.0
        R = zeros(2, 2)
        Rf = zeros(2, 2); Rf[1, 1] = q
        A = [1.0+r -c_bar+mu;
             0.0 1.0]
        B = [-1.0, 0.0]
        C = [sigma, 0.0]

        # == Compute solutions and simulate == #
        lq = LQ(Q, R, A, B, C; bet=bet, capT=T, rf=Rf)
        x0 = [0.0, 1.0]
        xp, up, wp = compute_sequence(lq, x0)
        @fact true => true  # just assert true if we made it to this point
    end

end  # facts
end  # module
