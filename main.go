package main

import (
	"context"
	"database/sql"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/endpoints"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"time"
	//	"github.com/heroiclabs/nakama-common/api"
	"github.com/heroiclabs/nakama-common/runtime"
	"go.uber.org/ratelimit"
	//	"github.com/mitchellh/mapstructure"

	"crypto/hmac"
	"crypto/sha256"
)

const (
	AWS_S3_REGION   = "frankfurt"
	AWS_S3_BUCKET   = "cardchat"
	AWS_S3_ENDPOINT = "https://n8j4.fra.idrivee2-28.com"
)

// session start
var sess = connectAWS()

func connectAWS() *session.Session {
	//	sess, err := session.NewSession(&aws.Config{Region: aws.String(AWS_S3_REGION)})
	//	if err != nil {
	//		panic(err)
	//	}

	defaultResolver := endpoints.DefaultResolver()
	s3CustResolverFn := func(service, region string, optFns ...func(*endpoints.Options)) (endpoints.ResolvedEndpoint, error) {
		if service == "s3" {
			return endpoints.ResolvedEndpoint{
				URL:           AWS_S3_ENDPOINT,
				SigningRegion: "custom-signing-region",
			}, nil
		}

		return defaultResolver.EndpointFor(service, region, optFns...)
	}
	sess, err := session.NewSessionWithOptions(session.Options{
		Config: aws.Config{
			Region:           aws.String("frankfurt"),
			EndpointResolver: endpoints.ResolverFunc(s3CustResolverFn),
		},
	})
	if err != nil {
		panic(err)
	}

	return sess
}

//session end

var svc = s3.New(sess)
var rl = ratelimit.New(100)

var UserList []UserInfo

type UserInfo struct {
	Name         string    `json:"name"`
	User_id      string    `json:"user_id"`
	Avatar_url   string    `json:"avatar_url"`
	Avatar_time  time.Time `json:"avatar_time"`
	PosX         float32   `json:"posX"`
	PosY         float32   `json:"posY"`
	Location     string    `json:"location"`
	LocationTime time.Time `json:"locationTime"`
	StartTime    time.Time `json:"startTime"`
}

type data struct {
	User_id  string  `json:"user_id"`
	Location string  `json:"location"`
	PosX     float32 `json:"posX"`
	PosY     float32 `json:"posY"`
	Action   string  `json:"action"`
}

type meta struct {
	User_id       string        `json:"user_id"`
	Location      string        `json:"location"`
	PosX          float32       `json:"posX"`
	PosY          float32       `json:"posY"`
	Role          string        `json:"role"`
	Azc           string        `json:"azc"`
	TotalPlayTime time.Duration `json: "totalPlayTime"`
}

type user struct {
	Name    string `json:"name"`
	User_id string `json:"user_id"`
	Meta    meta   `json:"meta"`
	Email   string `json:"email"`
}

// init nakama
func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {

	// initialize functions
	if err := initializer.RegisterRpc("list_files", listFiles); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}

	if err := initializer.RegisterRpc("upload_file", uploadFile); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}

	if err := initializer.RegisterRpc("download_file", downloadFile); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}

	if err := initializer.RegisterRpc("delete_file", deleteFile); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}

	/*  if err := initializer.RegisterRpc("current_users", currentUsers); err != nil {
	        logger.Error("Unable to register: %v", err)
	        return err
	    }
	*/
	if err := initializer.RegisterRpc("join", JoinStream); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}
	//if err := initializer.RegisterRpc("kill", killStream); err != nil {
	//	logger.Error("Unable to register: %v", err)
	//	return err
	//}
	if err := initializer.RegisterRpc("get_users", getUsers); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("get_all_users", getAllUsers); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("get_full_account", getFullAccount); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}
	// if err := initializer.RegisterRpc("set_full_account", setFullAccount); err != nil {
	// 	logger.Error("Unable to register: %v", err)
	// 	return err
	// }
	if err := initializer.RegisterRpc("move_position", movePos); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("leave", LeaveStream); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}
	if err := initializer.RegisterRpc("convert_image", convertImage); err != nil {
		logger.Error("Unable to register: %v", err)
		return err
	}

	if err := initializer.RegisterRpc("SessionCheck", rpcSessionCheck); err != nil {
		return err
	}

	logger.Info("Hello World!")
	return nil
}

// list all files

func listFiles(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {

	//svc := s3.New(sess)
	input := &s3.ListObjectsInput{
		Bucket: aws.String(AWS_S3_BUCKET),
	}

	result, err := svc.ListObjects(input)
	if err != nil {
		if aerr, ok := err.(awserr.Error); ok {
			switch aerr.Code() {
			case s3.ErrCodeNoSuchBucket:
				logger.Error(s3.ErrCodeNoSuchBucket, aerr.Error())
			default:
				logger.Error(aerr.Error())
			}
		} else {
			// Print the error, cast err to awserr.Error to get the Code and
			// Message from an error.
			logger.Error(err.Error())
		}
	}

	response, err := json.Marshal(result)
	if err != nil {
		return "", err
	}

	return string(response), nil
}

// download file

func downloadFile(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {

	var input map[string]string
	err := json.Unmarshal([]byte(payload), &input)
	if err != nil {
		return "", err
	}

	// Create S3 service client
	svc := s3.New(sess)

	req, _ := svc.GetObjectRequest(&s3.GetObjectInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		Key:    aws.String(input["url"]),
	})
	url, err := req.Presign(24 * time.Hour)

	if err != nil {
		logger.Error("Failed to generate a pre-signed url: ", err)
		return "error", err
	}

	// Display the pre-signed url

	// logger.Error(string(json_data) , url)

	response := `{ "url" : "` + url + `"}` // use JSON library to set values to avoid injection

	return response, nil

}

// upload file

func uploadFile(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {

	var input map[string]string
	err := json.Unmarshal([]byte(payload), &input)
	if err != nil {
		return "", err
	}
	// userId, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	userId := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)

	//	for m := range UserList {
	//		if UserList[m].User_id == userId {
	//			UserList[m] = UserList[len(UserList)-1]
	//			UserList = UserList[:len(UserList)-1]
	//		}
	//	}

	var location = input["type"] + "/" + userId + "/" + input["filename"] // sanitize inputs for control chars etc

	//svc := s3.New(sess)

	req, _ := svc.PutObjectRequest(&s3.PutObjectInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		Key:    aws.String(location),
	})
	url, err := req.Presign(15 * time.Minute)

	if err != nil {
		logger.Error("Failed to generate a pre-signed url: ", err)
		return "error", err
	}

	response := `{ "url" : "` + url + `", "location" :"` + location + `"}` // user JSON library to set field values

	return response, nil

}

func deleteFile(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {

	var input map[string]string
	err := json.Unmarshal([]byte(payload), &input)
	if err != nil {
		return "", err
	}
	extensions := []string{".txt", ".json", ".jpeg"}
	fileUser := input["user"]
	fileType := input["type"]
	fileName := input["name"]

	userId := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)

	// recieve current user, userfile, filecollection, filename

	// if user is actual user

	if userId == fileUser {

		// else if user is admin or moderator or artist

		// else error

		// delete files on aws

		svc := s3.New(sess)
		// !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! please sanatize paths to not have everything deleted...
		for _, i := range extensions {
			var location = fileType + "/" + fileUser + "/" + fileName + i

			request := &s3.DeleteObjectInput{
				Bucket: aws.String(AWS_S3_BUCKET),
				Key:    aws.String(location),
			}
			_, err = svc.DeleteObject(request)
			if err != nil {
				logger.Error("Storage delete error.")
			}
		}
		// delete storage

		objectIds := []*runtime.StorageDelete{
			&runtime.StorageDelete{
				Collection: fileType,
				Key:        fileName,
				UserID:     fileUser,
			},
		}

		err = nk.StorageDelete(ctx, objectIds)
		if err != nil {
			logger.Error("Storage delete error.")
		}

	}

	response := `{ "status" : "succes" }`

	return response, nil

}

/*
func currentUsers(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
//  svc := s3.New(sess)


  mode := uint8(123)
  label := "home"
  includeHidden := true
  includeNotHidden := true

  members, err := nk.StreamUserList(mode, "", "", label, includeHidden, includeNotHidden)
  if err != nil {
  logger.Error("error!", err)
  }


  var memberList []string

  for _, m := range members {
    logger.Error("Found user: %s\n", m.GetUserId());
    memberList = append(memberList, m.GetUserId())


    req, _ := svc.GetObjectRequest(&s3.GetObjectInput{
      Bucket: aws.String(AWS_S3_BUCKET),
      Key:    aws.String("/avatar/" + m.GetUserId() + ".jpg"),
    })

    url, err := req.Presign(15 * time.Minute)
   if err != nil {
        logger.Error("Failed to generate a pre-signed url: ", err)
     //   return "error", err
    }
  }

//  response, err := json.Marshal(members)

  response, err := json.Marshal(memberList)
  if err != nil {
    return "", err
  }


  return string(response), nil
  }

*/

func JoinStream(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok {
		// If user ID is not found, RPC was called without a session token.
		logger.Error("Invalid context")
	}
	sessionID, ok := ctx.Value(runtime.RUNTIME_CTX_SESSION_ID).(string)
	if !ok {
		// If session ID is not found, RPC was not called over a connected socket.
		logger.Error("Invalid context")
	}

	mode := uint8(123)
	hidden := false
	persistence := false
	label := payload
	includeHidden := true
	includeNotHidden := true

	//  svc := s3.New(sess)

	// get all users in session
	members, err := nk.StreamUserList(mode, "", "", label, includeHidden, includeNotHidden)
	if err != nil {
		logger.Error("error!", err)
	}

	var createSession = true
	var memberList []UserInfo

	//if false, create user
	var userExists = false

	for m := range UserList {
		if UserList[m].User_id == userID {
			userExists = true
			// add current location
			UserList[m].Location = payload
			UserList[m].LocationTime = time.Now()
			// add current time
		}
	}

	if !userExists {
		//	createSession = false
		// create user here //
		user := getAvatar(db, logger, userID)
		user.StartTime = time.Now()
		user.Location = payload
		user.LocationTime = time.Now()

		UserList = append(UserList, user)
		logger.Error("userAdded", UserList)
	}

	logger.Error("userList", UserList)

	for _, m := range members {
		// get avatar url from db
		if m.GetUserId() != userID {
			user := getAvatar(db, logger, m.GetUserId())
			user.Name = m.GetUsername()
			if err != nil {
				logger.Error("marshal error: ", err)
				return "error", err
			}
			// add info to object
			//  userInfo := UserInfo{m.GetUsername(),m.GetUserId(),url}

			// push object to array
			memberList = append(memberList, user)
			//UserList = append(UserList, user)

		}

	}

	response, err := json.Marshal(memberList)
	if err != nil {
		return "", err
	}
	if createSession {
		// create session
		if _, err := nk.StreamUserJoin(mode, "", "", label, userID, sessionID, hidden, persistence, ""); err != nil {
			return "", err
		}
	}

	return string(response), nil
}

// must be removed in production!
//func killStream(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
//	mode := uint8(123)
//	label := payload

//	nk.StreamClose(mode, "", "", label)

//	return "succesfully closed stream", nil
//}

// create function(get userid)
func getAvatar(db *sql.DB, logger runtime.Logger, userId string) UserInfo {

	for _, m := range UserList {
		if m.User_id == userId {
			if m.Avatar_time.After(time.Now()) {
				logger.Error("returning user in getavatar: ", m)
				return m

			}
		}
	}
	// else create avatar url
	var avatarURL string
	err := db.QueryRow("select avatar_url from users where id= $1;", userId).Scan(&avatarURL)

	req, _ := svc.GetObjectRequest(&s3.GetObjectInput{
		Bucket: aws.String(AWS_S3_BUCKET),
		Key:    aws.String(avatarURL),
	})

	signTime := 24 * time.Hour
	url, err := req.Presign(signTime)
	if err != nil {
		logger.Error("Failed to generate a pre-signed url: ", err)
	}

	var user UserInfo = UserInfo{
		User_id:     userId,
		Avatar_url:  url,
		Avatar_time: time.Now().AddDate(0, 0, 1),
	}

	//UserList = append(UserList, user)

	// put avatar url in userobject
	return user
}

func getUsers(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok {
		// If user ID is not found, RPC was called without a session token.
		logger.Error("Invalid context")
	}

	mode := uint8(123)
	label := payload
	includeHidden := true
	includeNotHidden := true

	//  svc := s3.New(sess)

	// get all users in session
	members, err := nk.StreamUserList(mode, "", "", label, includeHidden, includeNotHidden)
	if err != nil {
		logger.Error("error!", err)
	}

	var memberList []UserInfo

	// for each user
	for _, m := range members {
		// get avatar url from db
		if m.GetUserId() != userID {
			user := getAvatar(db, logger, m.GetUserId())
			user.Name = m.GetUsername()
			if user.Location != payload {

				user.Location = payload
				user.PosX = 0
				user.PosY = 0
			}
			logger.Error("object created: ", user)
			// userj, err := json.Marshal(user)
			// if err != nil {
			// 	logger.Error("marshal error: ", err)
			// 	//   return "error", err
			// }
			// add info to object
			//  userInfo := UserInfo{m.GetUsername(),m.GetUserId(),url}
			// push object to array
			memberList = append(memberList, user)

		}

	}

	response, err := json.Marshal(memberList)
	if err != nil {
		return "", err
	}

	return string(response), nil
}

func movePos(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userId, _ := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)

	var input data
	err := json.Unmarshal([]byte(payload), &input)
	if err != nil {
		return "", err
	}
	input.User_id = userId
	response, err := json.Marshal(input)
	if err != nil {
		return "", err
	}
	for m := range UserList {
		if UserList[m].User_id == userId {
			UserList[m].PosX = input.PosX
			UserList[m].PosY = input.PosY
			UserList[m].Location = input.Location
		}
	}

	var presences []runtime.Presence
	mode := uint8(123)
	label := input.Location
	// Data does not have to be JSON, but it's a convenient format.
	nk.StreamSend(mode, "", "", label, string(response), presences, true)

	return string(response), nil
}

// leave stream and save last local to db
func LeaveStream(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok {
		// If user ID is not found, RPC was called without a session token.
		logger.Error("Invalid context")
	}
	sessionID, ok := ctx.Value(runtime.RUNTIME_CTX_SESSION_ID).(string)
	if !ok {
		// If session ID is not found, RPC was not called over a connected socket.
		logger.Error("Invalid context")
	}

	if err := nk.StreamUserLeave(123, "", "", payload, userID, sessionID); err != nil {
		logger.Error("", err)
	}

	// Get the user's account details
	account, err := nk.AccountGetId(ctx, userID)
	if err != nil {
		logger.Error("", "error getting account data")
	}

	// Get the user's existing metadata
	metadata := make(map[string]interface{})
	if err := json.Unmarshal([]byte(account.User.Metadata), &metadata); err != nil {
		logger.Error("", "error deserializing metadata")
	}

	for m := range UserList {
		if UserList[m].User_id == userID {

			// logger.Error("last posX: ", UserList[m].PosX)
			metadata["posX"] = UserList[m].PosX
			// logger.Error("last posY: ", UserList[m].PosY)
			metadata["posY"] = UserList[m].PosY
			// logger.Error("last location: ", payload)
			metadata["location"] = payload
			logger.Error("exit stream metadata", metadata)
			logger.Error("exit stream userList", UserList[m])
			//get timerobject
			objectIds := []*runtime.StorageRead{&runtime.StorageRead{
				Collection: "achievements",
				Key:        "timers",
				UserID:     userID,
			},
			}

			records, err := nk.StorageRead(ctx, objectIds)
			if err != nil {
				logger.WithField("err", err).Error("Storage read error.")
			}
			timerObject := make(map[string]interface{})

			if len(records) > 0 {
				//	timerObject = records[0]

				if err := json.Unmarshal([]byte(records[0].Value), &timerObject); err != nil {
					logger.Error("", "error deserializing metadata")
				}
				logger.Error("records", timerObject)
			}
			// update timer object
			Timer := time.Now().Sub(UserList[m].LocationTime)
			oldTimer, _ := timerObject[UserList[m].Location].(time.Duration)

			timerObject[UserList[m].Location] = oldTimer + Timer

			// push time object
			val, err := json.Marshal(timerObject)

			objectIDs := []*runtime.StorageWrite{&runtime.StorageWrite{
				Collection: "achievements",
				Key:        "timers",
				UserID:     userID,
				Value:      string(val), // Value must be a valid encoded JSON object.
			},
			}

			_, err = nk.StorageWrite(ctx, objectIDs)
			if err != nil {
				logger.WithField("err", err).Error("Storage write error.")
			}

			// end of func
		}
	}

	if err := nk.AccountUpdateId(ctx, userID, "", metadata, "", "", "", "", ""); err != nil {
		logger.Error("", "error updating account data")
	}

	return "Success", nil
}

// heavy on resources, careful rate limit
func getAllUsers(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok {
		// If user ID is not found, RPC was called without a session token.
		logger.Error("Invalid context")
	}

	var queryResult string
	if err := db.QueryRow("select metadata from users where id= $1;", userID).Scan(&queryResult); err != nil {
		logger.Error("", err)
	}

	var metadata meta
	err := json.Unmarshal([]byte(queryResult), &metadata)
	if err != nil {
		logger.Error("", err)
	}

	if metadata.Role != "admin" {
		return "Sorry, not admin", nil
	}
	var users []user
	rows, err := db.Query("select id,username,metadata from users;")
	defer rows.Close()
	for rows.Next() {
		var metadata string
		var User user
		err = rows.Scan(&User.User_id, &User.Name, &metadata)
		err := json.Unmarshal([]byte(metadata), &User.Meta)
		if err != nil {
			logger.Error("", err)
		}
		users = append(users, User)
	}
	err = rows.Err()

	response, err := json.Marshal(users)
	if err != nil {
		return "", err
	}

	return string(response), nil
}

func getFullAccount(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok {
		// If user ID is not found, RPC was called without a session token.
		logger.Error("Invalid context")
	}

	var input map[string]string
	err := json.Unmarshal([]byte(payload), &input)
	if err != nil {
		return "", err
	}

	if input["id"] != "" {
		userID = input["id"]
	}
	var user user
	var metadata string
	if err := db.QueryRow("select  id,username,metadata,email from users where id= $1;", userID).Scan(&user.User_id, &user.Name, &metadata, &user.Email); err != nil {
		logger.Error("", err)
	}

	// var metadata meta
	err = json.Unmarshal([]byte(metadata), &user.Meta)
	if err != nil {
		logger.Error("", err)
	}

	// if metadata.Role != "admin" {
	// 	return "Sorry, not admin", nil
	// }

	response, err := json.Marshal(user)
	if err != nil {
		return "", err
	}

	return string(response), nil
}

func convertImage(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	var input map[string]string
	err := json.Unmarshal([]byte(payload), &input)

	logger.Error("recieved input", input)
	if err != nil {
		return "", err
	}

	var path string
	if input["height"] != "" {
		path += "/fit-in/" + input["width"] + "x" + input["height"] //nice to have: sanitize path
	}

	if input["format"] != "" {
		path += "/filters:format(" + input["format"] + ")" //nice to have: sanitize path
	}

	path += "/" + input["path"] //nice to have: sanitize path

	secret := "2jhTTNXH9wT37VKA" // place in envar + replace by newly generated secret

	h := hmac.New(sha256.New, []byte(secret))

	// Write Data to it
	h.Write([]byte(path))

	// Get result and encode as hexadecimal string
	signature := hex.EncodeToString(h.Sum(nil))

	url := "https://d1p8yo0yov6nht.cloudfront.net" + path + "?signature=" + signature //nice to have: sanitize path

	response := `{ "url" : "` + url + `"}` // string fixxxxx
	logger.Error("converted img", response)
	return string(response), nil
}

// noit functioning yet, needs to enable the notifications in front end most likely...
type SessionCheckResponse struct {
	AlreadyConnected bool `json:"already_connected"`
}

func rpcSessionCheck(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok {
		return "", runtime.NewError("no ID for user; must be authenticated", 3)
	}
	// See how many presences the user has on their notification stream.
	count, err := nk.StreamCount(0, userID, "", "")
	if err != nil {
		return "", fmt.Errorf("unable to count notification stream for user: %s", userID)
	}
	response, err := json.Marshal(&SessionCheckResponse{AlreadyConnected: count > 1})
	if err != nil {
		logger.Error("unable to encode json: %v", err)
		return "", errors.New("failed to encode json")
	}
	return string(response), nil
}

// rate limiter and lockout or exponential backof on login
// create a dev/prod variable to update code, based on state
// fix json shit strings
