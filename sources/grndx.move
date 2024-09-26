module grndx::just
{
    use std::signer;
    use aptos_std::smart_table;
    use aptos_std::math64;
    use std::signer::address_of;
    use aptos_framework::event;
    use aptos_framework::coin;
    use grndx::box_muller;
    use grndx::fixed_point64_with_sign::{FixedPoint64WithSign};
    use grndx::fixed_point64_with_sign;
    use grndx::math_fixed64_with_sign;
//    use grndx::factory;

    const EINCORRECT_RANGE: u64 = 0;
    const EINCORRECT_SIZE: u64 = 1;
    const ERR_MARKET_ACCOUNT_EXISTS: u64 = 115;
    const ERR_NOT_ALLOWED: u64 = 200;
    const ERR_NOT_OWNER: u64 = 104;
    const ERR_NO_MARKET_ACCOUNT: u64 = 114;
    const ERR_EXCEED_MAX_EXP: u64 = 701;
    const ERR_FP_PRECISION_LOSS: u64 = 702;
    const ERR_FP_EXCEED_DECIMALS: u64 = 703;

 // The market account itself.
    struct MarketAccount has store {
        // List of ids of orders which are still active for this account.
        instrumentBalance: coin::Coin<0x1::aptos_coin::AptosCoin>,
        marginBalance: coin::Coin<0x1::aptos_coin::AptosCoin>,
        ownerAddress: address,
        orderCounter: u64,
        contractBalance: u64,
        sideLong: bool,
        indexPosition:u64,
    }

  // Each market account is uniquely described by a protocol and user address.
    struct MarketAccountKey has store, copy, drop {
        protocolAddress: address,
        userAddress: address,
    }

    // Struct encapsilating all info for a market.
    struct Orderbook has key, store {
        marketAccountsSmart: smart_table::SmartTable<MarketAccountKey, MarketAccount>,
    }

    struct Message has key
    {
        my_message : u64
    }

#[event]
    struct PriceEvent has store, drop {
        price: u64,
    }

#[event]
struct RandomIndexEvent has store, drop {
        price: u64,
    }

    #[event]
struct LiquidatePositionEvent has store, drop {
        price: u64,
        account: address,
        contractBalance: u64,
    }

    #[event]
struct TradePositionEvent has store, drop {
        numbercont: u64,
        account: address,
        isLong: bool,
  
    }

    #[event]
struct TradeEvent has store, drop {
        numbercont: u64,
        account: address,
        isLong: bool,
        price: u64,
        contractBalance: u64,
    }





#[event]
struct OpenAccountEvent has store, drop {
        account: address,
    }

    struct RandomIndex has key
    {
        price : u64
    }


#[view]
    public fun get_random_index(): (u64)acquires RandomIndex {
        let message = borrow_global_mut<RandomIndex>(@grndx); //get the resouce
        message.price
    }


 entry fun create_random_index(account: &signer)acquires RandomIndex{
        let signer_address = address_of(account);
        //let new_roll:FixedPoint64WithSign =   box_muller::normal_r1();// randomness::u64_range(0, 6);
        if(!exists<RandomIndex>(signer_address)) { //If the resource does not exits corresponding to a given address
            let startIndex: u64 = 52500000;
            let message = RandomIndex {
                price : startIndex  //new_roll             //first create a resouce
            };
            move_to(account,message)        //move that resouce to the account
        }else{
            let _message = borrow_global_mut<RandomIndex>(signer_address); //get the resouce
        };
    }
#[lint::allow_unsafe_randomness]
#[randomness]
    entry fun crank_random_index(account: &signer)acquires RandomIndex,Orderbook, Message{
        assert!(address_of(account)==@grndx, ERR_NOT_OWNER);

        let signer_address = address_of(account);
        let new_roll:FixedPoint64WithSign =   box_muller::normal_r1();// randomness::u64_range(0, 6);

        if(!exists<RandomIndex>(signer_address)) { //If the resource does not exits corresponding to a given address
            let startIndex: u64 = 52500000; // if anybody reads this code, it is a joke, 52500000 is the price of a bitcoin in 2014
            let message = RandomIndex {
                price : startIndex  //new_roll             //first create a resouce
            };
            move_to(account,message)        //move that resouce to the account
        }else{                                 //If the resource exits corresponding to a given address
            let message = borrow_global_mut<RandomIndex>(signer_address); //get the resouce
//20 zeros and div 400                     
//            let myroll= fixed_point64_with_sign::create_from_rational( fixed_point64_with_sign::get_raw_value(new_roll) , 100000000000000000000, fixed_point64_with_sign::is_positive(new_roll));
//or
//21 zeros and div 200                                 
            let myroll= fixed_point64_with_sign::create_from_rational( fixed_point64_with_sign::get_raw_value(new_roll) , 1000000000000000000000, fixed_point64_with_sign::is_positive(new_roll));
            let my_exp = math_fixed64_with_sign::exp(myroll);
            let my_sqr = math_fixed64_with_sign::sqrt(my_exp            );
//            let mydivider:u128 =400<<64;
//or
            let mydivider:u128 =200<<64;
            let my_mult= math_fixed64_with_sign::div( 
                my_sqr,
                    fixed_point64_with_sign::create_from_raw_value( mydivider ,fixed_point64_with_sign::is_positive(new_roll))   //changed for fun :)
            );

            let myaddit:u128 =1<<64;
            let add_to_mult=fixed_point64_with_sign::add(
                fixed_point64_with_sign::create_from_raw_value( myaddit , true),
                my_mult

            ); 
            let my_Stm1=fixed_point64_with_sign::create_from_raw_value( (message.price as u128) , true);
            let my_res=math_fixed64_with_sign::mul(my_Stm1,add_to_mult);
                message.price= (fixed_point64_with_sign::get_raw_value(my_res) as u64);
           

        let event =RandomIndexEvent{
            price: message.price
        };  
        event::emit(event);
        
        if (message.price>100000000){
            message.price=52500000;
            resetall(account);
            let newevent =RandomIndexEvent{
                price: message.price
            };  
            event::emit(newevent);
        };

        if  (message.price<5000000){
            message.price=52500000;
            resetall(account);
            let newevent =RandomIndexEvent{
                price: message.price
            };  
            event::emit(newevent);
        };


        do_it(account,message.price);

        };
    }


 entry fun reset_random_index(account: &signer)acquires RandomIndex{
    let signer_address = address_of(account);
    let message = borrow_global_mut<RandomIndex>(signer_address); //get the res
  //let my_Stm1=fixed_point64_with_sign::create_from_raw_value( (message.price as u128) , true);
    message.price=  52500000;
     }

    // create a new market with new orderbook and market accounts
    //public entry fun init_market_entry(
    public entry fun in_it(
        owner: &signer
    ) {
        let ownerAddr = address_of(owner);
        assert!(ownerAddr == @grndx, ERR_NOT_ALLOWED);
        move_to(owner, Orderbook{
            marketAccountsSmart: smart_table::new(),
        });
    }

    //public entry fun open_market_account_entry(
        public entry fun hope_it(
        owner: &signer
    ) acquires  Orderbook {
        hope(owner, get_dx_market_account_key(owner));
    }

    public fun get_dx_market_account_key(
        user: &signer,
    ): MarketAccountKey {
        let userAddr = address_of(user);
        MarketAccountKey {
            protocolAddress: @grndx,
            userAddress: userAddr,
        }
    }

    inline fun get_market_addr(): address  {
        // assert_ferum_inited();
        // let info = borrow_global<FerumInfo>(@ferum);
        // let key = market_key<I, Q>();
        // assert!(table::contains(&info.marketMap, key), ERR_MARKET_NOT_EXISTS);
        // *table::borrow(&info.marketMap, key)
        @grndx
    }

    public fun hope(//open_market_account(
        owner: &signer,
        mak: MarketAccountKey,
    ) acquires  Orderbook {
        let ownerAddr = address_of(owner);
        let marketAddr = get_market_addr();
        let book = borrow_global_mut<Orderbook>(marketAddr);
        assert!(!smart_table::contains(&book.marketAccountsSmart, mak), ERR_MARKET_ACCOUNT_EXISTS);
        smart_table::add(&mut book.marketAccountsSmart, mak, MarketAccount{
          //activeOrders: vector[],
            instrumentBalance: coin::zero(),
            marginBalance: coin::zero(),
            ownerAddress: ownerAddr,
            orderCounter: 0,
            contractBalance: 0,
            sideLong: true,
            indexPosition: 0,
        });
        let event=OpenAccountEvent{
            account: ownerAddr
        };
        event::emit(event);
        //factory::mint_token(@grndx, b"Accounts", b"account", b"grndx", 0, b"url");

// collection_name: vector<u8>,
//     description : vector<u8>,
//     token_name: vector<u8>,
//     royalty: u64,
//     uri: vector<u8>,
      
    }

    //public entry fun deposit_to_market_account_entry(
    public entry fun depeche_it(
        owner: &signer,
        coinIAmt: u64,
        ) acquires  Orderbook {
        let accountKey = MarketAccountKey {
            protocolAddress: @grndx,
            userAddress: address_of(owner),
        };
        depeche(owner, accountKey, coinIAmt)
    }

    //public entry fun withdraw_from_market_account_entry(
    public entry fun without_it(
        owner: &signer,
        coinIAmt: u64, // Fixedpoint value.
    ) acquires  Orderbook {
        let accountKey = MarketAccountKey {
            protocolAddress: @grndx,
            userAddress: address_of(owner),
        };
        without(owner, accountKey, coinIAmt)
    }

public fun depeche( // deposit to market account
        owner: &signer,
        accountKey: MarketAccountKey,
        coinIAmt: u64, // Fixedpoint value.
    ) acquires  Orderbook {
        let marketAddr = get_market_addr();
        let book = borrow_global_mut<Orderbook>(marketAddr);
        {
        assert!(smart_table::contains(&book.marketAccountsSmart, accountKey), ERR_NO_MARKET_ACCOUNT);
        let marketAcc = smart_table::borrow_mut(&mut book.marketAccountsSmart, accountKey);
        assert!(owns_account(owner, &accountKey, marketAcc), ERR_NOT_OWNER);
        if (coinIAmt > 0) {
            //let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();
            let coinAmt = coin::withdraw<0x1::aptos_coin::AptosCoin>(owner, coinIAmt);
            coin::merge(&mut marketAcc.instrumentBalance, coinAmt);
    //        gamepoint::mint(@grndx,address_of(owner), 10);
        };
        };
    }

    // Returns true if the signer is able to perform mutative actions on an account and for the orders that the account
    // placed. Only the protocol or the address that created the account should be allowed.
    fun owns_account(
        owner: &signer,
        accountKey: &MarketAccountKey,
        marketAccount: &MarketAccount,
    ): bool {
        let ownerAddr = address_of(owner);
        ownerAddr == marketAccount.ownerAddress || ownerAddr == accountKey.protocolAddress
    }

    public fun without(
        owner: &signer,
        accountKey: MarketAccountKey,
        coinIAmt: u64, // Fixedpoint value.
    ) acquires  Orderbook {
        let marketAddr = get_market_addr();
        let ownerAddr = address_of(owner);
        let book = borrow_global_mut<Orderbook>(marketAddr);
        assert!(smart_table::contains(&book.marketAccountsSmart, accountKey), ERR_NO_MARKET_ACCOUNT);
        {
            let marketAcc = smart_table::borrow_mut(&mut book.marketAccountsSmart, accountKey);
            let coinWithAmt = math64::min(coinIAmt, coin::value(&marketAcc.instrumentBalance));
            assert!(owns_account(owner, &accountKey, marketAcc), ERR_NOT_OWNER);
            if (coinWithAmt > 0) {
                //let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();
                let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                    &mut marketAcc.instrumentBalance,
                    //fp_convert(coinIAmt, coinIDecimals, 1 /* FP_NO_PRECISION_LOSS */),
                    coinWithAmt,
                );
                coin::deposit(ownerAddr, coinAmt);
            };
        };
    }

//public entry  fun  send_reset_account_entry(
    public entry  fun  research_it(
     owner: &signer,
        
    ) acquires  Orderbook {
        let accountKey = MarketAccountKey {
            protocolAddress: @grndx,
            userAddress: address_of(owner),
        };
        research(owner,accountKey)
    }

public fun  research(   //send reset account
        owner: &signer,
        accountKey: MarketAccountKey,
        
        )  acquires Orderbook
        {
            let marketAddr = get_market_addr();
      //      let ownerAddr = address_of(owner);
            let book = borrow_global_mut<Orderbook>(marketAddr);
            {
                assert!(smart_table::contains(&book.marketAccountsSmart, accountKey), ERR_NO_MARKET_ACCOUNT);
                let marketAcc = smart_table::borrow_mut(&mut book.marketAccountsSmart, accountKey);
                assert!(owns_account(owner, &accountKey, marketAcc), ERR_NOT_OWNER);
                marketAcc.contractBalance=0;
                marketAcc.indexPosition=0;
                marketAcc.sideLong=true;
                //let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();
                let amount=coin::value(&marketAcc.marginBalance);//fp_convert(coin::value(&marketAcc.marginBalance), coinIDecimals, 1 /* FP_NO_PRECISION_LOSS */)*100;
                let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                    &mut marketAcc.marginBalance,
                    amount,
                    //fp_convert( amount , coinIDecimals, 1 /* FP_NO_PRECISION_LOSS */),
                );
                coin::merge(&mut marketAcc.instrumentBalance, coinAmt);
            };
        }

    public entry  fun  researchhawl_it(
     owner: &signer,
        
    ) acquires  Orderbook {
        // let accountKey = MarketAccountKey {
        //     protocolAddress: @grndx,
        //     userAddress: address_of(owner),
        // };
        assert!(address_of(owner)==@grndx, ERR_NOT_OWNER);
        researchhawl()
    }

public fun  researchhawl(   //send reset account
      //  owner: &signer,
        )  acquires Orderbook
        {
            
        let marketAddr = get_market_addr();
        let book = borrow_global_mut<Orderbook>(marketAddr);

  //   let i = 0;
  //   let len = smart_table::length(&book.marketAccountsSmart);

        smart_table::for_each_mut(&mut book.marketAccountsSmart, | _k, lmarketAccount | {
            let lmarketAccount: &mut MarketAccount = lmarketAccount;
         //   let pnl = lmarketAccount.indexPosition*indexdelta;
         //    assert!(owns_account(owner, &accountKey, marketAcc), ERR_NOT_OWNER);
            lmarketAccount.contractBalance=0;
                lmarketAccount.indexPosition=0;
                lmarketAccount.sideLong=true;
                //let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();
                let amount=coin::value(&lmarketAccount.marginBalance);//fp_convert(coin::value(&marketAcc.marginBalance), coinIDecimals, 1 /* FP_NO_PRECISION_LOSS */)*100;
                let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                    &mut lmarketAccount.marginBalance,
                    amount,
                    //fp_convert( amount , coinIDecimals, 1 /* FP_NO_PRECISION_LOSS */),
                );
                coin::merge(&mut lmarketAccount.instrumentBalance, coinAmt);
        });
    }

public fun  resetall(   //send reset account
        owner: &signer,
        )  acquires Orderbook
        {
        assert!(address_of(owner)==@grndx, ERR_NOT_OWNER);
        let marketAddr = get_market_addr();
        let book = borrow_global_mut<Orderbook>(marketAddr);

  //   let i = 0;
  //   let len = smart_table::length(&book.marketAccountsSmart);

        smart_table::for_each_mut(&mut book.marketAccountsSmart, | _k, lmarketAccount | {
            let lmarketAccount: &mut MarketAccount = lmarketAccount;
         //   let pnl = lmarketAccount.indexPosition*indexdelta;
         //    assert!(owns_account(owner, &accountKey, marketAcc), ERR_NOT_OWNER);
            lmarketAccount.contractBalance=0;
                lmarketAccount.indexPosition=0;
                lmarketAccount.sideLong=true;
                //let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();
                let amount=coin::value(&lmarketAccount.marginBalance);//fp_convert(coin::value(&marketAcc.marginBalance), coinIDecimals, 1 /* FP_NO_PRECISION_LOSS */)*100;
                let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                    &mut lmarketAccount.marginBalance,
                    amount,
                    //fp_convert( amount , coinIDecimals, 1 /* FP_NO_PRECISION_LOSS */),
                );
                coin::merge(&mut lmarketAccount.instrumentBalance, coinAmt);
        });
    }


    //public entry fun send_order_entry(
    public entry fun said_it(
        owner: &signer,
        leverage: u64, 
        cont: u64, 
        side: bool,
        // Fixedpoint value.
        //coinQAmt: u64, // Fixedpoint value.
    ) acquires  Orderbook {
        let accountKey = MarketAccountKey {
            protocolAddress: @grndx,
            userAddress: address_of(owner),
        };
        said(owner, accountKey,leverage, cont,side)
    }

    public fun  said(
        owner: &signer,
        accountKey: MarketAccountKey,
        leverage: u64,
        cont: u64, // Fixe
        sideLong: bool,
        )  acquires Orderbook
        {
            let marketAddr = get_market_addr();
       //     let ownerAddr = address_of(owner);
            let book = borrow_global_mut<Orderbook>(marketAddr);
            {
                assert!(smart_table::contains(&book.marketAccountsSmart, accountKey), ERR_NO_MARKET_ACCOUNT);
                let marketAcc = smart_table::borrow_mut(&mut book.marketAccountsSmart, accountKey);
                assert!(owns_account(owner, &accountKey, marketAcc), ERR_NOT_OWNER);
                if (cont>0){
                    let mycont:u64;//=cont;
                    if (marketAcc.sideLong ==sideLong) {
                        mycont=marketAcc.contractBalance+cont;
                    }else{
                        if (marketAcc.contractBalance>cont){
                            mycont=marketAcc.contractBalance-cont;
                        }
                        else{
                            mycont=cont-marketAcc.contractBalance;
                            marketAcc.sideLong=!marketAcc.sideLong;
                        }
                    };
                    marketAcc.contractBalance=mycont;
                
                    //transfer from instrumentBalance to marginBalance
                    let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();
                    let necessaryMargin=mycont* exp64(coinIDecimals)/leverage;  //100x LEVERAGE
                    let amount:u64;
                    if (coin::value(&marketAcc.marginBalance)> necessaryMargin){
                            amount=coin::value(&marketAcc.marginBalance)-necessaryMargin;
                            let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                                &mut marketAcc.marginBalance,
                                amount ,
                            );
                            coin::merge(&mut marketAcc.instrumentBalance, coinAmt);
                    }else{
                        amount= necessaryMargin-coin::value(&marketAcc.marginBalance);
                        let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                            &mut marketAcc.instrumentBalance,
                            amount,
                        );
                        coin::merge( &mut marketAcc.marginBalance, coinAmt);
                    };

                      let event=TradeEvent{
                        numbercont: cont,
                        account: marketAcc.ownerAddress,
                        isLong: sideLong,
                        price: 0,
                        contractBalance: amount  //necessaryMargin


                    };
                      event::emit(event)
                }; // if (cont >  0) { i think its useless :)
            };

    }

    public fun upstracking(account: &signer, newindex:u64,indexdelta:u64,isUp:bool) acquires Orderbook{
        let marketAddr = get_market_addr();
        let book = borrow_global_mut<Orderbook>(marketAddr);

     //   let i = 0;
  //      let len = smart_table::length(&book.marketAccountsSmart);

        smart_table::for_each_mut(&mut book.marketAccountsSmart, | _k, lmarketAccount | {
            let lmarketAccount: &mut MarketAccount = lmarketAccount;
            let pnl = lmarketAccount.indexPosition*indexdelta;
            let ud= (isUp && lmarketAccount.sideLong)||(!isUp && !lmarketAccount.sideLong);
            lmarketAccount.indexPosition=lmarketAccount.contractBalance*100000000/newindex;
            
            if (ud){
                let coinAmt = coin::withdraw<0x1::aptos_coin::AptosCoin>(account, pnl);
                coin::merge(&mut lmarketAccount.instrumentBalance, coinAmt);
            }else{
                if (coin::value(&lmarketAccount.instrumentBalance)< pnl){
                    let amount=coin::value(&lmarketAccount.marginBalance);
                    let event=TradeEvent{
                        price: newindex,
                        account: lmarketAccount.ownerAddress,
                        contractBalance: amount,
                        isLong: !lmarketAccount.sideLong,
                        numbercont:lmarketAccount.contractBalance
                    };
                    lmarketAccount.contractBalance=0;
                    lmarketAccount.sideLong=true;
                    //let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();
                    
                    let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                        &mut lmarketAccount.marginBalance,
                        amount,
                    );
                    coin::merge(&mut lmarketAccount.instrumentBalance, coinAmt);
                    // let event=LiquidatePositionEvent{
                    //     price: newindex,
                    //     account: lmarketAccount.ownerAddress,
                    //     contractBalance: amount,
                    // };

                    event::emit(event);



                };

                let mymin =math64::min(coin::value(&lmarketAccount.instrumentBalance), pnl);
                let coinAmt = coin::extract<0x1::aptos_coin::AptosCoin>(
                        &mut lmarketAccount.instrumentBalance,
                        mymin,
                    );
                    coin::deposit(address_of(account), coinAmt);
            };  
      });

    }

    public entry fun  do_it(account: &signer, msg: u64)  acquires Orderbook, Message{
assert!(address_of(account)==@grndx, ERR_NOT_OWNER);
        //should be only called by the owner !!!!!!!!!!!!!!!!

         let signer_address = signer::address_of(account);
        // assert!(signer_address == @cranker, ERR_NOT_ALLOWED);
        
        if(!exists<Message>(signer_address))  //If the resource does not exits corresponding to a given address
        {
            let message = Message {
                my_message : msg             //first create a resouce
            };
            move_to(account,message);        //move that resouce to the account
        }
        else                                 //If the resource exits corresponding to a given address
        {   
            let message = borrow_global_mut<Message>(signer_address); //get the resouce 
            let deltaindex:u64;
            let isUp:bool;
            if (msg>message.my_message){
                deltaindex=msg-message.my_message;
                isUp=true;
            }else{
                deltaindex=message.my_message-msg;
                isUp=false;
            };
            message.my_message=msg;     
            upstracking(account,message.my_message,deltaindex,isUp);      //doing all the job
                                    //update the resource
        };

        let event =PriceEvent{
            price: msg
        };  
        // Emit the event just defined.
        event::emit(event)
    }

    //struct MarketAccountView {
        struct MarketingView {

        instrumentBalanceSmart: u64, // Fixedpoint
        marginBalanceSmart: u64,
        contractBalanceSmart: u64,
        sideLongSmart: bool,
        smartTableLength: u64,
        coinDecimals:u8,
        indexPosition:u64,
    }

#[view]
    //public fun view_balance( user: address) : MarketAccountView acquires  Orderbook {
        public fun view_balance( user: address) : MarketingView acquires  Orderbook {

        let accountKey = MarketAccountKey {
            protocolAddress: @grndx,
            userAddress: user,
        };
        let marketAddr = get_market_addr();
        let book = borrow_global<Orderbook>(marketAddr);
        
        // assert!(table::contains(&book.marketAccounts, accountKey), ERR_NO_MARKET_ACCOUNT);
        // let marketAccount = table::borrow(&book.marketAccounts, accountKey);
        let marketAccountsSmart = smart_table::borrow(&book.marketAccountsSmart, accountKey);
        let coinIDecimals = coin::decimals<0x1::aptos_coin::AptosCoin>();

        //MarketAccountView {
            MarketingView {
            
            instrumentBalanceSmart: coin::value(&marketAccountsSmart.instrumentBalance),
            marginBalanceSmart: coin::value(&marketAccountsSmart.marginBalance),
            contractBalanceSmart: marketAccountsSmart.contractBalance,
            sideLongSmart: marketAccountsSmart.sideLong,
            smartTableLength: smart_table::length(&book.marketAccountsSmart),
            coinDecimals: coinIDecimals,
            indexPosition:marketAccountsSmart.indexPosition,
        }
    }

#[view]
    public fun view_index() : u64 acquires Message{
        let message = borrow_global<Message>(@grndx);
        message.my_message
    }


    // Programatic way to get a power of 10.
    fun exp64(e: u8): u64 {
        if (e == 0) {
            1
        } else if (e == 1) {
            10
        } else if (e == 2) {
            100
        } else if (e == 3) {
            1000
        } else if (e == 4) {
            10000
        } else if (e == 5) {
            100000
        } else if (e == 6) {
            1000000
        } else if (e == 7) {
            10000000
        } else if (e == 8) {
            100000000
        } else if (e == 9) {
            1000000000
        } else if (e == 10) {
            10000000000
        } else if (e == 11) {
            100000000000
        } else if (e == 12) {
            1000000000000
        } else if (e == 13) {
            10000000000000
        } else if (e == 14) {
            100000000000000
        } else if (e == 15) {
            100000000000000
        } else if (e == 16) {
            100000000000000
        } else if (e == 17) {
            100000000000000
        } else if (e == 18) {
            100000000000000
        } else if (e == 19) {
            100000000000000
        } else if (e == 20) {
            100000000000000
        } else {
            abort ERR_EXCEED_MAX_EXP
        }
    }

    


}