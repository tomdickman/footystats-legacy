import { Context } from "../../context"

const hello = async (_parent: any, _args: any, {}: Context) => {
  return 'Hello World'
}

export default hello
