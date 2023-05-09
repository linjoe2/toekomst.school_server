function InitModule(
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  initializer: nkruntime.Initializer
) {
  logger.info("TypeScript module loaded.");
 // initializer.registerBeforeAuthenticateEmail(userRegisterEmailCheck);
 // initializer.registerAfterAuthenticateEmail(AddUserSettings);
 // initializer.registerBeforeWriteStorageObjects(beforeWriteStorage);
 // initializer.registerBeforeUpdateAccount(beforeUpdateProfile);

  // initializer.registerRpc('move_position', movePosition);
  initializer.registerRpc("set_full_account", setFullAccount);
  initializer.registerRpc("update_object_admin", updateObjectAdmin);
  initializer.registerRpc("create_object_admin", createObjectAdmin);
  initializer.registerRpc("delete_object_admin", deleteObjectAdmin);
  initializer.registerRpc("list_all_storage_object", listAllStorageObjects);
  initializer.registerRpc("get_all_houses_object", getAllHousesObject);
  initializer.registerRpc("send_artpiece", sendArtpiece);
  initializer.registerRpc("scan_card", scanCard);
  initializer.registerRpc("reset_password_admin", resetPasswordAdmin);

  
}

// Reference InitModule to avoid it getting removed on build
!InitModule && InitModule.bind(null);

// only allow registration if admin

let userRegisterEmailCheck: any = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.AuthenticateEmailRequest
): any {
  logger.error("before register: ", data.account?.vars!);
  if (data.create) {
    let userId: string = data.account?.vars?.userId!;
    // userId = ctx.userId;
    let users: nkruntime.User[];
    try {
      users = nk.usersGetId([userId]);
    } catch (error) {
      logger.error("Failed to get user: %s", error.message);
      throw error;
    }

    if (users[0].metadata.Role != "admin") {
      throw Error("Must be admin to create new user");
    }
  }
  // important!
  return data;
};

let AddUserSettings: any = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.AuthenticateEmailRequest
): any {
  if (!!ctx.vars) {
    logger.error("test", ctx.vars);
    let azc: string = ctx?.vars?.azc!;
    let role: string = ctx?.vars?.role!;
    let avatar: string = ctx?.vars?.avatar!;
    let home: string = ctx?.vars?.home!;

    let metadata = { azc: azc, role: role };
    nk.accountUpdateId(
      ctx.userId,
      null,
      null,
      null,
      null,
      null,
      avatar,
      metadata
    );
    // userID, username, displayname, timezone, location, lang, avatar,metadata

    // create home

    let homeData = {
      url: home,
      posX: 0,
      posY: 0,
      username: ctx?.username,
    };
    let newObjects: nkruntime.StorageWriteRequest[] = [
      {
        collection: "home",
        key: azc,
        userId: ctx.userId,
        value: homeData,
        permissionRead: 2,
      },
    ];

    try {
      nk.storageWrite(newObjects);
    } catch (error) {
      logger.error("save error", error);
      return '{"status": "create home failed"}';
    }

    logger.error("working", "working");
    return;
  }
};

let movePosition: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json = JSON.parse(payload);
  let streamId: nkruntime.Stream = {
    mode: 123,
    label: json.location,
  };

  nk.streamSend(streamId, payload);
};

let getAccount: any = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.AuthenticateEmailRequest
): any {};

let setFullAccount: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json = JSON.parse(payload);
  let result: any;

  let users: any = nk.usersGetId([ctx.userId]);

  if (users[0].metadata.Role != "admin") {
    throw Error("Must be admin to update user");
  }

  if (!!json.password) {
    // validate pasword requirements
    result = nk.bcryptHash(json.password);
    // logger.error("pass", result);
    let query = "UPDATE users SET password = $1 WHERE id = $2 ";
    let parameters = [result, json.id];
    try {
      let dbResponse = nk.sqlExec(query, parameters);
      logger.error("pass updated", dbResponse);
    } catch (error) {
      // Handle error
      logger.error("pass update failed", error);
    }
  }

  if (!!json.email) {
    let query = "UPDATE users SET email = $1 WHERE id = $2 ";
    let parameters = [json.email, json.id];
    try {
      let dbResponse = nk.sqlExec(query, parameters);
      logger.error("email updated", dbResponse);
    } catch (error) {
      // Handle error
      logger.error("email update failed", result);
    }
  }

  if (!!json.metadata) {
    let query = "UPDATE users SET metadata = $1 WHERE id = $2 ";
    let parameters = [json.metadata, json.id];
    try {
      let dbResponse = nk.sqlExec(query, parameters);
      logger.error("metadata updated", dbResponse);
    } catch (error) {
      // Handle error
      logger.error("metadata update failed", result);
    }
  }
};

let createObjectAdmin: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json;

  if (typeof payload == "string") {
    json = JSON.parse(payload);
  } else {
    json = payload;
  }

  if (typeof json.value == "string") json.value = JSON.parse(json.value);

  let users: any = nk.usersGetId([ctx.userId]);

  let pub: any = 1;

  if (
    !(
      users[0].metadata.Role == "admin" || users[0].metadata.Role == "moderator"
    )
  ) {
    return '{"status": "not admin or moderator"}';
  }

  if (json.pub === true) {
    pub = 2;
  }

  let newObjects: nkruntime.StorageWriteRequest[] = [
    {
      collection: json.type,
      key: json.name,
      userId: json.id,
      value: json.value,
      permissionRead: pub,
    },
  ];

  try {
    nk.storageWrite(newObjects);
  } catch (error) {
    logger.error("save error", error);
    return '{"status": "failed"}';
  }
  return '{"status": "succes"}';
};

let updateObjectAdmin: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json;

  logger.error("json before", json);

  if (typeof payload == "string") {
    json = JSON.parse(payload);
  } else {
    json = payload;
  }
  json.value = JSON.parse(json.value);

  let users: any = nk.usersGetId([ctx.userId]);

  let pub: any = 1;
  if (
    users[0].metadata.Role != "admin" &&
    users[0].metadata.Role != "moderator"
  ) {
    return '{"status": "not admin"}';
  }

  logger.error("json after", json);

  if (json.pub === true) {
    pub = 2;
  }

  let newObjects: nkruntime.StorageWriteRequest[] = [
    {
      collection: json.type,
      key: json.name,
      userId: json.id,
      value: json.value,
      permissionRead: pub,
    },
  ];

  try {
    nk.storageWrite(newObjects);
  } catch (error) {
    logger.error("save error", error);
    return '{"status": "failed"}';
  }
  return '{"status": "succes"}';
};

let deleteObjectAdmin: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json = JSON.parse(payload);
  let users: any = nk.usersGetId([ctx.userId]);

  if (
    !(
      users[0].metadata.Role == "admin" || users[0].metadata.Role == "moderator"
    )
  ) {
    throw Error("Must be admin to delete object");
  }

  if (!!!json.type || !!!json.name || !!!json.id) {
    throw Error("Must fill in all details");
  }

  logger.error("json", json);

  let query =
    "DELETE FROM storage WHERE collection = $1 AND key = $2 AND user_id = $3";
  let parameters = [json.type, json.name, json.id];
  try {
    let dbResponse = nk.sqlExec(query, parameters);
    logger.error("delete done", dbResponse);
  } catch (error) {
    // Handle error
    logger.error("delete failed", error);
    return '{"status": "failed"}';
  }

  return '{"status": "succes"}';
};

let listAllStorageObjects: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json = JSON.parse(payload);
  let rows: nkruntime.SqlQueryResult = [];
  let query;
  let parameters;
  logger.error("json", json);

  if (!!json.id) {
    query = ` SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND stor.user_id = $2;`;
    parameters = [json.type, json.id];
  } else {
    query = ` SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 ORDER BY stor.update_time desc limit 50;`; //TOP(50)
    parameters = [json.type];
  }
  try {
    rows = nk.sqlQuery(query, parameters);
  } catch (error) {
    // Handle error
    logger.error("delete failed", error);
    return '{"status": "failed"}';
  }
  rows.forEach((row) => {
    row.value = JSON.parse(String.fromCharCode(...row.value));
    row.permission_read = row.read;
  });
  logger.error("pickup done", rows);

  return JSON.stringify(rows);
};

let beforeUpdateProfile: any = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.UserUpdateAccount
): any {
  logger.error("write ctx:", ctx);
  logger.error("write data:", data.avatarUrl);
  if (data.avatarUrl != undefined) {
    let users: any = nk.usersGetId([ctx.userId]);

    let newAvatarVersion =
      Number(data.avatarUrl.split("/")[2].split("_")[0]) || 0;
    let oldAvatarVersion = users[0].metadata.LastAvatarVersion || 0;
    if (newAvatarVersion >= oldAvatarVersion) {
      users[0].metadata.LastAvatarVersion = newAvatarVersion;
    }

    let query = "UPDATE users SET metadata = $1 WHERE id = $2 ";
    let parameters = [users[0].metadata, ctx.userId];
    try {
      let dbResponse = nk.sqlExec(query, parameters);
      logger.error("metadata updated", dbResponse);
    } catch (error) {
      // Handle error
      logger.error("metadata update failed");
    }

    logger.error("avatarVersion", newAvatarVersion);
    logger.error("users[0]", users[0]);
  }

  return data;
};

let beforeWriteStorage: any = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  data: nkruntime.WriteStorageObjectsRequest
): any {
  logger.error("write ctx:", ctx);
  logger.error("write data:", data);

  data.objects.forEach((object) => {
    if (object.collection === "liked") {
      // // logger.error("write ctx:", ctx);
      // logger.error("sent by:", ctx.userId);
      // logger.error("recieved by:", JSON.parse(object.value).user_id);
      // logger.error("picture liked:", JSON.parse(object.value).key);

      let receiverId = JSON.parse(object.value).user_id;
      let subject = "new Like!";
      let content = {
        key: JSON.parse(object.value).key,
        url: JSON.parse(object.value).url,
        username: ctx.username,
      };
      let code = 1;
      let senderId = ctx.userId; // who the message if from
      let persistent = true;

      nk.notificationSend(
        receiverId,
        subject,
        content,
        code,
        senderId,
        persistent
      );
    }
  });

  return data;
};

let getAllHousesObject: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json = JSON.parse(payload);
  // let rows: nkruntime.SqlQueryResult = [];
  let query;
  let parameters;

  logger.error("json", json);
  if (typeof json.user_id == "string") {
    query = ` SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND key = $2 AND user_id = $3`;
    parameters = ["home", json.location, json.user_id];
  } else {
    query = ` SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND key = $2`;
    parameters = ["home", json.location];
  }

  let rows;
  try {
    rows = nk.sqlQuery(query, parameters);

    rows.forEach((row) => {
      row.value = JSON.parse(String.fromCharCode(...row.value));
      // row.value.convertedUrl = getCovertImage(nk,logger,row.value.url,"128","png")
      row.permission_read = row.read;

      // count  stopmotion objects from user
      // count  drawing objects from user

      let query = `SELECT COUNT(*) FROM storage WHERE collection = $1 AND user_id = $2 AND read = 2;`;
      let stopmotion = nk.sqlQuery(query, ["stopmotion", row.user_id]);
      let drawing = nk.sqlQuery(query, ["drawing", row.user_id]);

      row.artworks = {
        stopmotion: stopmotion[0].count,
        drawing: drawing[0].count,
      };
    });
  } catch (error) {
    // Handle error
    logger.error("home recieve failed", error);
  }

  return JSON.stringify(rows);
};

function getCovertImage(nk, logger, url, size, format) {
  let method: nkruntime.RequestMethod = "post";

  let headers = {
    "Content-Type": "application/json",
    Accept: "application/json",
  };

  let body = { path: url, width: size, height: size, format: "png" };
  let res = {} as nkruntime.HttpResponse;

  logger.error("body recieved", body);

  try {
    res = nk.httpRequest(
      "http://localhost:7350/v2/rpc/convert_image?http_key=defaulthttpkey",
      method,
      headers,
      body
    );
    logger.error("url recieved", res);
  } catch (error) {
    // Handle error
    logger.error("url error recieved", error);
  }

  return res;
}

// validate pasword requirements

let sendArtpiece: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {
  let json = JSON.parse(payload);
  logger.error("artpiece recieved", json);

  let receiverId = json.userId,
    subject = "recieved new Image",
    code = 2,
    senderId = ctx.userId,
    persistent = true;

  nk.notificationSend(receiverId, subject, json, code, senderId, persistent);
};



// reset password function for admin
let resetPasswordAdmin: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {

  let users: any = nk.usersGetId([ctx.userId]);

  if (users[0].metadata.Role != "admin") {
    throw Error("Must be admin to update user");
  }

  let json = JSON.parse(payload);
  logger.error("artpiece recieved", json);
  let userId = json.id;
  let email = json.email;
  let password = json.password;

  try {
    nk.linkEmail(userId, email, password);
  } catch (error) {
    // Handle error
    logger.error("failed password update", error);
    return '{"status":"failed"}'
  }
  return '{"status":"succes"}'
}






let scanCard: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {


  let json = JSON.parse(payload);
  let rows: nkruntime.SqlQueryResult = [];
  let query;
  let parameters;

// get object from db collection = card, key = id

  query = ` SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND stor.key = $2;`;
  parameters = ["card", json.key];


try {
  rows = nk.sqlQuery(query, parameters);
} catch (error) {
  // Handle error
  logger.error("delete failed", error);
  return '{"status": "failed"}';
}
let row = rows[0]
row.value = JSON.parse(String.fromCharCode(...row.value));
row.permission_read = row.read;



return JSON.stringify(row)
};




let activateCard: nkruntime.RpcFunction = function (
  ctx: nkruntime.Context,
  logger: nkruntime.Logger,
  nk: nkruntime.Nakama,
  payload: string
) {


// get username of current user and card user
 let users: any = nk.usersGetId([ctx.userId]);
// become friends
// start chat
// update object with new userID, with old id in history



//   let json = JSON.parse(payload);
//   let rows: nkruntime.SqlQueryResult = [];
//   let query;
//   let parameters;

// // get object from db collection = card, key = id

//   query = ` SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND stor.key = $2;`;
//   parameters = ["card", json.key];


// try {
//   rows = nk.sqlQuery(query, parameters);
// } catch (error) {
//   // Handle error
//   logger.error("delete failed", error);
//   return '{"status": "failed"}';
// }
// let row = rows[0]
// row.value = JSON.parse(String.fromCharCode(...row.value));
// row.permission_read = row.read;


// get username of current user and card user
// let users: any = nk.usersGetId([ctx.userId]);
// become friends
// start chat
// update object with new userID, with old id in history


};
