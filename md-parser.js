const fs = require('fs')
const util = require('util')
const aReadFile = util.promisify(fs.readFile)
const areaddir = util.promisify(fs.readdir)
const fm = require('front-matter')
const remark = require('remark')
const html = require('remark-html')

const settings = {
  commonmark: true,
}

async function main() {
  const files = await areaddir('./pages', {}).then(files => {
    return files.filter(f => f.match(/\.md$/g))
  })

  let posts = []
  for await (const file of files) {
    const content = await aReadFile(`./pages/${file}`, 'utf8').then(async data => {
      return data
    })

    const frontmatter = fm(content)

    frontmatter.body = await remark()
      .data('settings', settings)
      .use(html)
      .process(frontmatter.body)
      .then(vfile => {
        return String(vfile)
      })

    posts.push(frontmatter)
  }

  process.stdout.write(JSON.stringify(posts))
}

module.exports = main

if (require.main === module) {
  main()
}
