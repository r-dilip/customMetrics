

function logEveryNSeconds() {
    setTimeout(() => {
        var date = new Date();
        var time = date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds();
        console.log(JSON.stringify(
            { 
                "name": "Fixed Double Escape Bug\r\n",
                "Age": 3, 
                "Gender":"Male\r\n", 
                "res":
                {
                    "statusCode":200,
                    "header":"HTTP/1.1 200 OK\r\nETag: W/\"127d-nCvUb0hr569afAcI24r44H0PF5E\"\r\n"
                } 
            }
        ));
        logEveryNSeconds();
    }, 10000)
}

logEveryNSeconds();



