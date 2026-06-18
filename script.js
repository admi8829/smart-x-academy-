const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

function getFiles(dir, files_) {
  files_ = files_ || [];
  const files = fs.readdirSync(dir);
  for (var i in files) {
    const name = dir + '/' + files[i];
    if (fs.statSync(name).isDirectory()) {
      getFiles(name, files_);
    } else if (name.endsWith('.dart')) {
      files_.push(name);
    }
  }
  return files_;
}

const allDartFiles = getFiles('lib');
const unused = [];

allDartFiles.forEach(file => {
  if (file === 'lib/main.dart') return;
  const basename = path.basename(file);
  
  try {
    const out = execSync(`grep -rnl "${basename}" lib/ | grep -v "${file}"`).toString();
    if (out.trim().length === 0) {
      unused.push(file);
    }
  } catch(e) {
    unused.push(file);
  }
});

console.log('Unused files:');
console.log(unused.join('\n') || 'None');
