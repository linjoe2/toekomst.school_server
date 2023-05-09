function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, initializer: nkruntime.Initializer) {
    initializer.registerrpc('upload_image', uploadimage);
    initializer.registerBeforeAuthenticateEmail(userRegisterEmailCheck);
};



let uploadImage: nkruntime.RpcFunction =
        function (ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, payload: string) {
    // We'll assume payload was sent as JSON and decode it.
    let json = JSON.parse(payload);
    json.userId = ctx;    
    json.test ='changed'

    return JSON.stringify(json); 

}


let userRegisterEmailCheck: any =
        function(ctx: nkruntime.Context, logger: nkruntime.Logger, nk: nkruntime.Nakama, data: nkruntime.AuthenticateEmailRequest): any {

	if(data.create == true){
	    let userId:string = data.account?.vars?.userId!;
	    // userId = ctx.userId;	
	    let users: nkruntime.User[];
	    try {
	        users = nk.usersGetId([ userId ]);
	    } catch (error) {
	        logger.error('Failed to get user: %s', error.message);
	        throw error;
	    }
	
	    if (users[0].metadata.role != 'admin') {
	        throw Error('Must be admin to create new user');
		    }
	}
    // important!
    return data;


}



