function InitModule(ctx, logger, nk, initializer) {
  logger.info('TypeScript module loaded.');
  initializer.registerBeforeAuthenticateEmail(userRegisterEmailCheck);
  initializer.registerRpc("upload_image", uploadImage);
  initializer.registerRpc('join', joinFunction);
  initializer.registerRpc('move_position', movePosition);
}

!InitModule && InitModule.bind(null);

var userRegisterEmailCheck = function userRegisterEmailCheck(ctx, logger, nk, data) {
  var _a, _b;

  if (data.create == true) {
    var userId = (_b = (_a = data.account) === null || _a === void 0 ? void 0 : _a.vars) === null || _b === void 0 ? void 0 : _b.userId;
    var users;

    try {
      users = nk.usersGetId([userId]);
    } catch (error) {
      logger.error('Failed to get user: %s', error.message);
      throw error;
    }

    if (users[0].metadata.role != 'admin') {
      throw Error('Must be admin to create new user');
    }
  }

  return data;
};

var uploadImage = function uploadImage(ctx, logger, nk, payload) {
  var json = JSON.parse(payload);
  json.test = 'changed';
  var userId = json.userID;
  var value = {
    "path": json.path
  };
  var newObjects = [{
    collection: "save",
    key: "save1",
    userId: userId,
    value: value
  }];

  try {
    nk.storageWrite(newObjects);
  } catch (error) {}

  return JSON.stringify(json);
};

var joinFunction = function joinFunction(ctx, logger, nk, payload) {
  var streamId = {
    mode: 123,
    label: 'Avatar Position'
  };
  var hidden = false;
  var persistence = false;
  nk.streamUserJoin(ctx.userId, ctx.sessionId, streamId, hidden, persistence);
};

var movePosition = function movePosition(ctx, logger, nk, payload) {
  var streamId = {
    mode: 123,
    label: 'Avatar Position'
  };
  nk.streamSend(streamId, payload);
};
