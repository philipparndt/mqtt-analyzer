#!/usr/bin/env zx

if (process.argv.length !== 4 || (process.argv[3] !== "apply" &&  process.argv[3] !== "undo")) {
    console.log(`Usage: ${process.argv[2]} <apply/undo>`)
    process.exit(1)
}
const file = "../src/Pods/Pods.xcodeproj/project.pbxproj"

const apply = process.argv[3] === "apply"
const content = fs.readFileSync(file, "utf8")
const lines = content.split("\n")
const fix =  "settings = {ATTRIBUTES = (Public, ); }; }; /*RLMFIX*/"

const result = []
let ctr = 0
for (let line of lines) {
    if (apply && line.match(/.*(RLM|Realm)[a-zA-Z+_0-9]*\.h.*isa = PBXBuildFile.*};$/g)) {
        const replaced = line.replace(/};$/g, fix)
        result.push(replaced)
        ctr++
    }
    else if (!apply && line.endsWith(fix)) {
        const replaced = line.substring(0, line.length - fix.length) + "};"
        result.push(replaced)
        ctr++
    }
    else {
        result.push(line)
    }
}

console.log(`Found ${ctr} lines to fix.`)
fs.writeFileSync(file, result.join("\n"))