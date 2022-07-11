import { Context } from "../../context"

const players = async (_parent: any, _args: any, { db }: Context) => {
  let result = []

  try {
    const response = await db.query('SELECT * FROM player')
    result = response.rows.map(row => ({
      ...row,
      roundstats: async () => { 
        const roundStatsResp = await db.query('SELECT * FROM roundstats WHERE playerid = $1', [row.id])
        return roundStatsResp.rows
      }
    }))
  } catch(error) {
    console.log(error)
  }

  return result
}

export default players
