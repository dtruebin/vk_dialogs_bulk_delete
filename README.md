## Intro
VK.com does not provide a bulk mode for removing old/unneeded chats (dialogs), and deleting them one by one is too slow, as it requires confirmation on every step.  
To work around this issue, I created a couple of bash (perhaps, the only thing I'm not utterly terrible at) scripts leveraging VK API.

## Getting ready
### Authorize the app

In order to use VK API, [authorize the app](https://oauth.vk.com/authorize?client_id=6487379&display=page&redirect_uri=https://oauth.vk.com/blank.html&scope=messages&response_type=token&v=5.76) I specifically created for this project.  
Alternatively, [create your own standalone app](https://vk.com/editapp?act=create), replace XXXXX in the link below with the ID of your app and open the link in a browser:
```
https://oauth.vk.com/authorize?client_id=XXXXX&display=page&redirect_uri=https://oauth.vk.com/blank.html&scope=messages&response_type=token&v=5.76
```

If you see the following, log out of VK, log back in and try authorizing the app again
```json
{"error":"invalid_request","error_description":"Security Error"}
```

Once the app is authorized, you will be redirected to a page with a URL such as the one below:
https://oauth.vk.com/blank.html#access_token=0dba993a40a7a4ba&expires_in=86400&user_id=12345

### Create a config

Clone the repo and create a configuration file based on the sample
```bash
$ cp vk.conf.sam vk.conf
```
Then, populate `vk.conf` accordingly.

### Install [jq](https://stedolan.github.io/jq/)
The scripts are using `jq` (tested with v1.3), so it must be installed and added to `PATH`.

## Fun part

### Get the list of dialogs/people

Generate `vk_users_from_dialogs.csv` file containing "user_id,name" pairs of people you talked to
```bash
$ ./vk_get_users_from_dialogs.sh
```
Group chats, bots and other special users are not included into the resulting file.

### Filter the list

Edit the CSV file by leaving only those users, dialogs with whom you want to _remove_.

### Delete the dialogs

```bash
$ ./vk_delete_dialogs_with_users.sh [FILE]
```
If `FILE` is omitted, `vk_users_from_dialogs.csv` will be processed.
