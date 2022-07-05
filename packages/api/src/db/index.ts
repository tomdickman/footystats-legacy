import 'dotenv/config'
import { Pool, PoolConfig, QueryResult } from 'pg'

const { 
  PGHOST,
  PGPORT,
  PGDATABASE,
  PGPASSWORD,
  PGUSER,
 } = process.env

const config: PoolConfig = {
  connectionString: `postgresql://${PGUSER}:${PGPASSWORD}@${PGHOST}:${PGPORT}/${PGDATABASE}`
}

config.ssl = {
  rejectUnauthorized: false,
}

const pool = new Pool(config)

const query = async (text: string, params: any = []) => {
  return pool.query(text, params)
}

export type Database = {
  query: (text: string, params?: any) => Promise<QueryResult<any>>
}


const db: Database = {
  query
}

export default db
