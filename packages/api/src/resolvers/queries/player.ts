import { Context } from "../../context"

export type PlayerQueryArgs = {
  id: string
}

const player = async (_parent: any, { id }: PlayerQueryArgs, { db }: Context) => {
  let result

  try {
    const response = await db.query('SELECT * FROM player WHERE id = $1', [id])
    result = response.rows[0]
    result.roundstats = async () => {
      const roundStatsResp = await db.query('SELECT * FROM roundstats WHERE playerid = $1', [id])
      return roundStatsResp.rows
    }
  } catch(error) {
    console.log(error)
  }

  return result
}

export default player
