const { exec } = require('child_process')
const path = require('path')
const script = path.join(__dirname, 'cache-http.sh')

exec(script, (err, stdout, stderr) => {
  if (err) {
    console.log(err)
    process.abort()
  }

  // the *entire* stdout and stderr (buffered)
  console.log(`stdout: ${stdout}`);
});