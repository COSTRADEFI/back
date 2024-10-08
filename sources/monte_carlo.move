// The concept of Monte Carlo simulation is quite simple.
// It involves obtaining the return process of the asset and discretizing it, then using small time intervals to calculate the changes in asset prices.
// For example, considering token prices, their returns follow a Geometric Brownian motion.
// A discretized stochastic differential equation:
//
// dSt = mu * St * dt + sigma * St * dWt
//
// where Wt represents a Wiener process.
// After applying Ito's formula, we obtain Equation 2 as the main equation for Monte Carlo simulation to predict token prices
// Where Zt follows a standard normal distribution.
//
// St = S(t-1) * exp( (mu - 0.5 * sigma**2) * dt + sigma * sqrt(dt) * Zt )
//
// We need to tranform all random numbers of uniform distribution to random numbers of normal distribution to get Zt.
// Box-muller method supports that.
module grndx::monte_carlo {
    use std::vector;
    use grndx::fixed_point64_with_sign::{Self, FixedPoint64WithSign};
    use grndx::math_fixed64_with_sign;
    use grndx::box_muller;
    use aptos_framework::randomness;

    // s0: price value on Step 0.
    // r: Asset`s historical return
    // s0, r (mu), sigma, t: need to move 64 bit to left ( << 64) from the client side
    // nsteps, nrep: keep original values in u128.
    fun generate_spath(s0: u128, r: u128, sigma: u128, t: u128, nsteps: u64, nrep: u64, is_positive_r: bool, random_numbers: vector<FixedPoint64WithSign>): vector<vector<u128>> {
       
        // initialize a two dimension vector.
        // initialize the first column with s0.
        let spath = init_2d_vector(nsteps, nrep, s0);
        
        // derivative(t)
        let dt = math_fixed64_with_sign::div(
            fixed_point64_with_sign::create_from_raw_value(t, true),
            fixed_point64_with_sign::create_from_raw_value((nsteps as u128) << 64, true),
        ); 

        // Calculate 0.5 * sigma**2
        let second_param = math_fixed64_with_sign::mul(
            fixed_point64_with_sign::create_from_rational(1,2, true),
            math_fixed64_with_sign::pow(
                fixed_point64_with_sign::create_from_raw_value(sigma, true),
                2
            )
        );
        
        // Calculate r - 0.5 * sigma**2
        let sign_result: FixedPoint64WithSign = fixed_point64_with_sign::sub(
            fixed_point64_with_sign::create_from_raw_value(r, is_positive_r),
            second_param
        );

        // Calculate (r - 0.5 * sigma**2) * dt
        let sign_nudt: FixedPoint64WithSign = math_fixed64_with_sign::mul(
            sign_result,
            dt
        );
        
        // Calculate sigma * sqrt(dt)
        let sidt: FixedPoint64WithSign = math_fixed64_with_sign::mul(
            fixed_point64_with_sign::create_from_raw_value(sigma, true),
            math_fixed64_with_sign::sqrt(dt),
        );

        let i = 0;

        while(i < nrep) {
            let j = 0;
            let row_i = vector::borrow_mut(&mut spath, i);
            while( j < nsteps) {
                let col_j = vector::borrow(row_i, j);

                // Calculate S(t-1) * exp( (mu - 0.5 * sigma**2) * dt + sigma * sqrt(dt) * Zt )
                let col_j_plus_1_fixed_point64 = math_fixed64_with_sign::mul(
                    fixed_point64_with_sign::create_from_raw_value(*col_j, true),
                    calculate_exp(sign_nudt, sidt, *vector::borrow(&random_numbers, (i+1)*(j+1) - 1))
                );
                *vector::borrow_mut(row_i, j + 1) = fixed_point64_with_sign::get_raw_value(col_j_plus_1_fixed_point64);
                j = j + 1;
            };
            i = i + 1;
        };

        spath

    }
#[lint::allow_unsafe_randomness]
    public fun generate_spath_with_permutation(s0: u128, r: u128, sigma: u128, t: u128, nsteps: u64, nrep: u64, is_positive_r: bool): vector<vector<u128>> {
            let random_numbers: vector<FixedPoint64WithSign> = generate_random_using_permutation(nrep, nsteps);
            generate_spath(s0, r, sigma, t, nsteps, nrep, is_positive_r, random_numbers)
    }
#[lint::allow_unsafe_randomness]
    public fun generate_spath_with_range(s0: u128, r: u128, sigma: u128, t: u128, nsteps: u64, nrep: u64, max_excl: u64, is_positive_r: bool):vector<vector<u128>> {
            let random_numbers: vector<FixedPoint64WithSign> = generate_random_using_u64_range(nrep, nsteps, max_excl);
            generate_spath(s0, r, sigma, t, nsteps, nrep, is_positive_r, random_numbers)
    }

    // Calculate this formula:
    // exp( (mu - 0.5 * sigma**2) * dt + sigma * sqrt(dt) * Zt )
    fun calculate_exp(sign_nudt: FixedPoint64WithSign, sidt: FixedPoint64WithSign, random_number: FixedPoint64WithSign): FixedPoint64WithSign  {
        

        //sigma * sqrt(dt) * Zt
        let mul_result: FixedPoint64WithSign = math_fixed64_with_sign::mul(
                sidt,
                random_number
        );

        let sign_add_result = fixed_point64_with_sign::add(
            sign_nudt,
            mul_result
        );

        let exp = math_fixed64_with_sign::exp(
                sign_add_result
        );

        exp
    }

    // Initialize a matrix 0 with rows and columns. 
    public fun init_2d_vector(step: u64, rep: u64, first_column_value: u128): vector<vector<u128>> {
        let spath = vector::empty<vector<u128>>();
        let i = 0;
        while (i < rep) {

            let row = vector::empty<u128>();
            let j = 0;
            while (j < step + 1) {
                if (j == 0) {
                    vector::push_back(&mut row, first_column_value);
                } else {
                    vector::push_back(&mut row, 0);
                };
                
                j = j + 1;
            };

            vector::push_back(&mut spath, row);
            i = i +1;
        };

        spath

    }

    // Use randomness permution
    fun generate_random_using_permutation(nrep: u64, nsteps: u64): vector<FixedPoint64WithSign> {
        let range = nrep * nsteps + 1;
        let uniform_random_numbers = randomness::permutation(range);
        let (_, index_of_zero) = vector::index_of<u64>(&uniform_random_numbers, &(0));
        vector::remove(&mut uniform_random_numbers, index_of_zero);
        let random_numbers = box_muller::uniform_to_normal(uniform_random_numbers, (range as u128));
        random_numbers
    }

     // Use randomness u64_range
    fun generate_random_using_u64_range(nrep: u64, nsteps: u64, max_excl: u64): vector<FixedPoint64WithSign> {
        let size = nrep * nsteps;
        let i = 0;
        let uniform_random_numbers = vector::empty<u64>();
        while( i < size) {
            // to ensure all random numbers belong to (0,1) after the standardization process.
            let number = randomness::u64_range(1, max_excl);
            vector::push_back(&mut uniform_random_numbers, number);
            i = i + 1;
        };

        let random_numbers = box_muller::uniform_to_normal(uniform_random_numbers, (max_excl as u128));
        random_numbers
    }
}