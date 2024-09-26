module grndx::prob_distribution {
    use aptos_framework::randomness;
    
    use std::vector;
    use grndx::box_muller;
    use grndx::exponential_transform;
    use grndx::laplacian_transform;
    use grndx::chisquare_transform;
    use grndx::fixed_point64_with_sign::{FixedPoint64WithSign};
    use grndx::fixed_point64_with_sign;
    use aptos_std::fixed_point64::{Self, FixedPoint64};
    use std::signer::address_of;
    use aptos_framework::event;
    use grndx::math_fixed64_with_sign;

    const EINCORRECT_RANGE: u64 = 0;
    const EINCORRECT_SIZE: u64 = 1;

#[event]
    struct IndexEvent has store, drop {
        price: u64,
    }


#[event]
struct RandomIndexEvent has store, drop {
        price: u128,
    }


    struct MessageRessource has key
    {
        my_Rmessage : u64
    }


    struct RandomIndex has key
    {
        price : u128
    }

    // Get random numbers following Normal Distribution
    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_nd_random_numbers(size: u64, min_incl: u64, max_excl: u64): (vector<FixedPoint64WithSign>) {
        assert!(max_excl > min_incl, EINCORRECT_RANGE);
        assert!(size > 0, EINCORRECT_SIZE);

        let range = max_excl - min_incl;
        let random_numbers: vector<u64> = vector::empty<u64>();
        let i = 0 ;

        while( i < size ) {
           
            let random_number = randomness::u64_range(min_incl + 1, max_excl);
            random_number = random_number - min_incl;
            vector::push_back(&mut random_numbers, random_number);
            i = i + 1;
        };

        let normalized_random_numbers = box_muller::uniform_to_normal(random_numbers, (range as u128));
        normalized_random_numbers

    }

    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_nd_random_number(): (FixedPoint64WithSign) {
        box_muller::normal_r1()
    }

    #[view]
    public fun get_nd_random_index(): (u64)acquires MessageRessource {
        let message = borrow_global_mut<MessageRessource>(@grndx); //get the resouce
        message.my_Rmessage
    }

#[randomness]
    entry fun set_nd_random_number(account: &signer)acquires MessageRessource{
        let signer_address = address_of(account);
        let new_roll:FixedPoint64WithSign =   box_muller::normal_r1();// randomness::u64_range(0, 6);

        if(!exists<MessageRessource>(signer_address)) { //If the resource does not exits corresponding to a given address
            let startIndex: u64 = 10000000;
            let message = MessageRessource {
                my_Rmessage : startIndex  //new_roll             //first create a resouce
            };
            move_to(account,message)        //move that resouce to the account
        }else{                                 //If the resource exits corresponding to a given address
            let message = borrow_global_mut<MessageRessource>(signer_address); //get the resouce
           
            //message.my_Rmessage=message.my_Rmessage * 100005/100000; //update the resouce
            let my_exp = math_fixed64_with_sign::exp(
                new_roll
            );
            let my_sqr = math_fixed64_with_sign::sqrt(
                my_exp
            );
            // let my_mult= math_fixed64_with_sign::div( 
            //     my_sqr,
            //         fixed_point64_with_sign::create_from_raw_value(200, fixed_point64_with_sign::is_positive(new_roll))
            // );

            // let my_Stm1=fixed_point64_with_sign::create_from_raw_value( (message.my_Rmessage as u128) << 64, true);


            if ( fixed_point64_with_sign::is_positive(new_roll)){

                message.my_Rmessage=  10000000;//(fixed_point64_with_sign::get_raw_value(my_Stm1)  << 64 )   ;  
                //10000000;//message.my_Rmessage *(1+my_mult); //update the resouce

            }else{
                message.my_Rmessage=10000000;//message.my_Rmessage *(1-100105/100000); //update the resouce
            };
           

        let event =IndexEvent{
            price: message.my_Rmessage
        };  
        // Emit the event just defined.
        event::emit(event)
        };
    }



#[randomness]
    entry fun randomly_pick_winner()  {
        randomly_get_nd_random_number();
    }

    public(friend) fun randomly_get_nd_random_number(): (FixedPoint64WithSign) {
        box_muller::normal_r1()
    }



    // Get random numbers following Exponential Distribution
    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_ed_random_numbers(size: u64, min_incl: u64, max_excl: u64, lambda: u128): (vector<FixedPoint64>) {

        assert!(max_excl > min_incl, EINCORRECT_RANGE);
        assert!(size > 0, EINCORRECT_SIZE);
        let lambda_fixed_point64 = fixed_point64::create_from_raw_value(lambda);

        let range = max_excl - min_incl;
        let random_numbers: vector<FixedPoint64> = vector::empty<FixedPoint64>();
        let i = 0 ;

        while( i < size ) {
            let random_number = randomness::u64_range(min_incl, max_excl);
            random_number = random_number - min_incl;
            let ed_random_number = exponential_transform::uniform_to_exponential((random_number as u128), (range as u128), lambda_fixed_point64);
            vector::push_back(&mut random_numbers, ed_random_number);
            i = i + 1;
        };
        random_numbers

    }
    // Get random numbers following Laplacian Distribution
    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_ll_random_numbers(size: u64, min_incl: u64, max_excl: u64, mu: u128, beta: u128): (vector<FixedPoint64WithSign>) {

        assert!(max_excl > min_incl, EINCORRECT_RANGE);
        assert!(size > 0, EINCORRECT_SIZE);

        let range = max_excl - min_incl;
        let random_numbers: vector<FixedPoint64WithSign> = vector::empty<FixedPoint64WithSign>();
        let i = 0 ;

        while( i < size ) {
            
            let random_number = randomness::u64_range(min_incl + 1, max_excl);
            random_number = random_number - min_incl;
            let ll_random_number = laplacian_transform::uniform_to_laplacian((random_number as u128), (range as u128), mu, beta);
            vector::push_back(&mut random_numbers, ll_random_number);
            i = i + 1;
        };
        random_numbers

    }

    // Get random numbers following Chi-square Distribution
    #[view]
    #[lint::allow_unsafe_randomness]
    public fun get_cq_random_numbers(size: u64, min_incl: u64, max_excl: u64): (vector<FixedPoint64>) {

        assert!(max_excl > min_incl, EINCORRECT_RANGE);
        assert!(size > 0, EINCORRECT_SIZE);

        let range = max_excl - min_incl;
        let random_numbers: vector<u64> = vector::empty<u64>();
        let i = 0 ;

        while( i < size ) {
            let random_number = randomness::u64_range(min_incl + 1, max_excl);
            random_number = random_number - min_incl;
            vector::push_back(&mut random_numbers, random_number);
            i = i + 1;
        };
        let ll_random_numbers = chisquare_transform::uniform_to_chisquare(random_numbers, (range as u128));
        ll_random_numbers
    }



#[view]
    public fun get_random_index(): (u128)acquires RandomIndex {
        let message = borrow_global_mut<RandomIndex>(@grndx); //get the resouce
        message.price
    }


 entry fun create_random_index(account: &signer)acquires RandomIndex{
        let signer_address = address_of(account);
        //let new_roll:FixedPoint64WithSign =   box_muller::normal_r1();// randomness::u64_range(0, 6);

        if(!exists<RandomIndex>(signer_address)) { //If the resource does not exits corresponding to a given address
            let startIndex: u128 = 10000000;
            let message = RandomIndex {
                price : startIndex  //new_roll             //first create a resouce
            };
            move_to(account,message)        //move that resouce to the account
        }else{
                let _message = borrow_global_mut<RandomIndex>(signer_address); //get the resouce
        };
    }


#[randomness]
    entry fun crank_random_index2(account: &signer) acquires RandomIndex{
        let signer_address = address_of(account);
        let new_roll:FixedPoint64WithSign =   box_muller::normal_r1();// randomness::u64_range(0, 6);

        if(!exists<RandomIndex>(signer_address)) { //If the resource does not exits corresponding to a given address
            let startIndex: u128 = 10000000;
            let message = RandomIndex {
                price : startIndex  //new_roll             //first create a resouce
            };
            move_to(account,message)        //move that resouce to the account
        }else{                                 //If the resource exits corresponding to a given address
            let message = borrow_global_mut<RandomIndex>(signer_address); //get the resouce
           
            //message.my_Rmessage=message.my_Rmessage * 100005/100000; //update the resouce
            let my_exp = math_fixed64_with_sign::exp(
                new_roll
            );
            let my_sqr = math_fixed64_with_sign::sqrt(
                my_exp
            );
            

            let my_mult= math_fixed64_with_sign::div( 
                my_sqr,
                    fixed_point64_with_sign::create_from_raw_value( 200 << 64 ,fixed_point64_with_sign::is_positive(new_roll))
            );

            let add_to_mult=fixed_point64_with_sign::add(
                fixed_point64_with_sign::create_from_raw_value( 1<<64 , true),
                my_mult

            ); 

          

            let my_Stm1=fixed_point64_with_sign::create_from_raw_value( (message.price as u128) , true);

            let my_res=math_fixed64_with_sign::mul(my_Stm1,add_to_mult);


            //message.price=  fixed_point64_with_sign::get_raw_value(add_to_mult);
message.price=  fixed_point64_with_sign::get_raw_value (add_to_mult);
            // if (    fixed_point64_with_sign::is_positive(new_roll)){
            //     message.price=  fixed_point64_with_sign::get_raw_value (add_to_mult);

            // }else{
            //     message.price= 2<<64;

            // };


            // if ( fixed_point64_with_sign::is_positive(new_roll)){
            //     message.price=  fixed_point64_with_sign::get_raw_value(my_Stm1)   ;  
            // }else{
            //     message.price=  fixed_point64_with_sign::get_raw_value(my_Stm1)   ;  
            // };

        let event =RandomIndexEvent{
            price: message.price
        };  
        // Emit the event just defined.
        event::emit(event);
        };
      
    }


#[randomness]
    entry fun crank_random_index(account: &signer)acquires MessageRessource{
        let signer_address = address_of(account);
        let new_roll:FixedPoint64WithSign =   box_muller::normal_r1();// randomness::u64_range(0, 6);

        if(!exists<MessageRessource>(signer_address)) { //If the resource does not exits corresponding to a given address
            let startIndex: u64 = 10000000;
            let message = MessageRessource {
                my_Rmessage : startIndex  //new_roll             //first create a resouce
            };
            move_to(account,message)        //move that resouce to the account
        }else{                                 //If the resource exits corresponding to a given address
            let message = borrow_global_mut<MessageRessource>(signer_address); //get the resouce
           
            //message.my_Rmessage=message.my_Rmessage * 100005/100000; //update the resouce
            let myroll= fixed_point64_with_sign::create_from_rational( fixed_point64_with_sign::get_raw_value(new_roll) ,      1000000000000000000000000 , fixed_point64_with_sign::is_positive(new_roll));
            
            let my_exp = math_fixed64_with_sign::exp(
                myroll
            );
            let my_sqr = math_fixed64_with_sign::sqrt(
                my_exp
            );

            let mydivider:u128 =200<<64;
            let my_mult= math_fixed64_with_sign::div( 
                my_sqr,
                    fixed_point64_with_sign::create_from_raw_value( mydivider ,fixed_point64_with_sign::is_positive(new_roll))
            );

            let myaddit:u128 =1<<64;
            let add_to_mult=fixed_point64_with_sign::add(
                fixed_point64_with_sign::create_from_raw_value( myaddit , true),
                my_mult

            ); 
            let my_Stm1=fixed_point64_with_sign::create_from_raw_value( (message.my_Rmessage as u128) , true);
            let my_res=math_fixed64_with_sign::mul(my_Stm1,add_to_mult);
                message.my_Rmessage= (fixed_point64_with_sign::get_raw_value(my_res) as u64);
           

        let event =IndexEvent{
            price: message.my_Rmessage
        };  



        // Emit the event just defined.
        event::emit(event)
        };
    }


 entry fun reset_random_index(account: &signer)acquires RandomIndex,MessageRessource{
    let signer_address = address_of(account);
    let message = borrow_global_mut<RandomIndex>(signer_address); //get the res
  //let my_Stm1=fixed_point64_with_sign::create_from_raw_value( (message.price as u128) , true);
    message.price=  10000000;
    let messageressource = borrow_global_mut<MessageRessource>(signer_address); //get the res
    messageressource.my_Rmessage=  10000000;

 }






}