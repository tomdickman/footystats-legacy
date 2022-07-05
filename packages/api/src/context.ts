import { ContextFunction } from 'apollo-server-core'
import db, { Database } from './db'

export type Context = {
  db: Database
}

const context: ContextFunction = (): Context => ({
  db,
})

export default context
