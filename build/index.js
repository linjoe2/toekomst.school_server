function _toConsumableArray(arr) {
  return _arrayWithoutHoles(arr) || _iterableToArray(arr) || _unsupportedIterableToArray(arr) || _nonIterableSpread();
}

function _arrayWithoutHoles(arr) {
  if (Array.isArray(arr)) return _arrayLikeToArray(arr);
}

function _iterableToArray(iter) {
  if (typeof Symbol !== "undefined" && iter[Symbol.iterator] != null || iter["@@iterator"] != null) return Array.from(iter);
}

function _unsupportedIterableToArray(o, minLen) {
  if (!o) return;
  if (typeof o === "string") return _arrayLikeToArray(o, minLen);
  var n = Object.prototype.toString.call(o).slice(8, -1);
  if (n === "Object" && o.constructor) n = o.constructor.name;
  if (n === "Map" || n === "Set") return Array.from(o);
  if (n === "Arguments" || /^(?:Ui|I)nt(?:8|16|32)(?:Clamped)?Array$/.test(n)) return _arrayLikeToArray(o, minLen);
}

function _arrayLikeToArray(arr, len) {
  if (len == null || len > arr.length) len = arr.length;

  for (var i = 0, arr2 = new Array(len); i < len; i++) arr2[i] = arr[i];

  return arr2;
}

function _nonIterableSpread() {
  throw new TypeError("Invalid attempt to spread non-iterable instance.\nIn order to be iterable, non-array objects must have a [Symbol.iterator]() method.");
}

function InitModule(ctx, logger, nk, initializer) {
  logger.info("TypeScript module loaded.");
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

!InitModule && InitModule.bind(null);

var setFullAccount = function setFullAccount(ctx, logger, nk, payload) {
  var json = JSON.parse(payload);
  var result;
  var users = nk.usersGetId([ctx.userId]);

  if (users[0].metadata.Role != "admin") {
    throw Error("Must be admin to update user");
  }

  if (!!json.password) {
    result = nk.bcryptHash(json.password);
    var query = "UPDATE users SET password = $1 WHERE id = $2 ";
    var parameters = [result, json.id];

    try {
      var dbResponse = nk.sqlExec(query, parameters);
      logger.error("pass updated", dbResponse);
    } catch (error) {
      logger.error("pass update failed", error);
    }
  }

  if (!!json.email) {
    var _query = "UPDATE users SET email = $1 WHERE id = $2 ";
    var _parameters = [json.email, json.id];

    try {
      var _dbResponse = nk.sqlExec(_query, _parameters);

      logger.error("email updated", _dbResponse);
    } catch (error) {
      logger.error("email update failed", result);
    }
  }

  if (!!json.metadata) {
    var _query2 = "UPDATE users SET metadata = $1 WHERE id = $2 ";
    var _parameters2 = [json.metadata, json.id];

    try {
      var _dbResponse2 = nk.sqlExec(_query2, _parameters2);

      logger.error("metadata updated", _dbResponse2);
    } catch (error) {
      logger.error("metadata update failed", result);
    }
  }
};

var createObjectAdmin = function createObjectAdmin(ctx, logger, nk, payload) {
  var json;

  if (typeof payload == "string") {
    json = JSON.parse(payload);
  } else {
    json = payload;
  }

  if (typeof json.value == "string") json.value = JSON.parse(json.value);
  var users = nk.usersGetId([ctx.userId]);
  var pub = 1;

  if (!(users[0].metadata.Role == "admin" || users[0].metadata.Role == "moderator")) {
    return '{"status": "not admin or moderator"}';
  }

  if (json.pub === true) {
    pub = 2;
  }

  var newObjects = [{
    collection: json.type,
    key: json.name,
    userId: json.id,
    value: json.value,
    permissionRead: pub
  }];

  try {
    nk.storageWrite(newObjects);
  } catch (error) {
    logger.error("save error", error);
    return '{"status": "failed"}';
  }

  return '{"status": "succes"}';
};

var updateObjectAdmin = function updateObjectAdmin(ctx, logger, nk, payload) {
  var json;
  logger.error("json before", json);

  if (typeof payload == "string") {
    json = JSON.parse(payload);
  } else {
    json = payload;
  }

  json.value = JSON.parse(json.value);
  var users = nk.usersGetId([ctx.userId]);
  var pub = 1;

  if (users[0].metadata.Role != "admin" && users[0].metadata.Role != "moderator") {
    return '{"status": "not admin"}';
  }

  logger.error("json after", json);

  if (json.pub === true) {
    pub = 2;
  }

  var newObjects = [{
    collection: json.type,
    key: json.name,
    userId: json.id,
    value: json.value,
    permissionRead: pub
  }];

  try {
    nk.storageWrite(newObjects);
  } catch (error) {
    logger.error("save error", error);
    return '{"status": "failed"}';
  }

  return '{"status": "succes"}';
};

var deleteObjectAdmin = function deleteObjectAdmin(ctx, logger, nk, payload) {
  var json = JSON.parse(payload);
  var users = nk.usersGetId([ctx.userId]);

  if (!(users[0].metadata.Role == "admin" || users[0].metadata.Role == "moderator")) {
    throw Error("Must be admin to delete object");
  }

  if (!!!json.type || !!!json.name || !!!json.id) {
    throw Error("Must fill in all details");
  }

  logger.error("json", json);
  var query = "DELETE FROM storage WHERE collection = $1 AND key = $2 AND user_id = $3";
  var parameters = [json.type, json.name, json.id];

  try {
    var dbResponse = nk.sqlExec(query, parameters);
    logger.error("delete done", dbResponse);
  } catch (error) {
    logger.error("delete failed", error);
    return '{"status": "failed"}';
  }

  return '{"status": "succes"}';
};

var listAllStorageObjects = function listAllStorageObjects(ctx, logger, nk, payload) {
  var json = JSON.parse(payload);
  var rows = [];
  var query;
  var parameters;
  logger.error("json", json);

  if (!!json.id) {
    query = " SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND stor.user_id = $2;";
    parameters = [json.type, json.id];
  } else {
    query = " SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 ORDER BY stor.update_time desc limit 50;";
    parameters = [json.type];
  }

  try {
    rows = nk.sqlQuery(query, parameters);
  } catch (error) {
    logger.error("delete failed", error);
    return '{"status": "failed"}';
  }

  rows.forEach(function (row) {
    row.value = JSON.parse(String.fromCharCode.apply(String, _toConsumableArray(row.value)));
    row.permission_read = row.read;
  });
  logger.error("pickup done", rows);
  return JSON.stringify(rows);
};

var getAllHousesObject = function getAllHousesObject(ctx, logger, nk, payload) {
  var json = JSON.parse(payload);
  var query;
  var parameters;
  logger.error("json", json);

  if (typeof json.user_id == "string") {
    query = " SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND key = $2 AND user_id = $3";
    parameters = ["home", json.location, json.user_id];
  } else {
    query = " SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND key = $2";
    parameters = ["home", json.location];
  }

  var rows;

  try {
    rows = nk.sqlQuery(query, parameters);
    rows.forEach(function (row) {
      row.value = JSON.parse(String.fromCharCode.apply(String, _toConsumableArray(row.value)));
      row.permission_read = row.read;
      var query = "SELECT COUNT(*) FROM storage WHERE collection = $1 AND user_id = $2 AND read = 2;";
      var stopmotion = nk.sqlQuery(query, ["stopmotion", row.user_id]);
      var drawing = nk.sqlQuery(query, ["drawing", row.user_id]);
      row.artworks = {
        stopmotion: stopmotion[0].count,
        drawing: drawing[0].count
      };
    });
  } catch (error) {
    logger.error("home recieve failed", error);
  }

  return JSON.stringify(rows);
};

var sendArtpiece = function sendArtpiece(ctx, logger, nk, payload) {
  var json = JSON.parse(payload);
  logger.error("artpiece recieved", json);
  var receiverId = json.userId,
      subject = "recieved new Image",
      code = 2,
      senderId = ctx.userId,
      persistent = true;
  nk.notificationSend(receiverId, subject, json, code, senderId, persistent);
};

var resetPasswordAdmin = function resetPasswordAdmin(ctx, logger, nk, payload) {
  var users = nk.usersGetId([ctx.userId]);

  if (users[0].metadata.Role != "admin") {
    throw Error("Must be admin to update user");
  }

  var json = JSON.parse(payload);
  logger.error("artpiece recieved", json);
  var userId = json.id;
  var email = json.email;
  var password = json.password;

  try {
    nk.linkEmail(userId, email, password);
  } catch (error) {
    logger.error("failed password update", error);
    return '{"status":"failed"}';
  }

  return '{"status":"succes"}';
};

var scanCard = function scanCard(ctx, logger, nk, payload) {
  var json = JSON.parse(payload);
  var rows = [];
  var query;
  var parameters;
  query = " SELECT stor.value , usr.username, stor.user_id, stor.key, stor.collection, stor.update_time, stor.read  FROM storage AS stor INNER JOIN users AS usr ON stor.user_id = usr.id WHERE collection = $1 AND stor.key = $2;";
  parameters = ["card", json.key];

  try {
    rows = nk.sqlQuery(query, parameters);
  } catch (error) {
    logger.error("delete failed", error);
    return '{"status": "failed"}';
  }

  var row = rows[0];
  row.value = JSON.parse(String.fromCharCode.apply(String, _toConsumableArray(row.value)));
  row.permission_read = row.read;
  return JSON.stringify(row);
};
