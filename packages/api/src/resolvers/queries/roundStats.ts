import { Context } from "../../context"

export type RoundStatsQueryArgs = {
  playerid: string
  game: number
}

const roundStats = async (_parent: any, { playerid, game }: RoundStatsQueryArgs, { db }: Context) => {
  let result

  try {
    const response = await db.query('SELECT * FROM roundstats WHERE playerid = $1 AND game = $2', [playerid, game])
    result = response.rows[0]
  } catch(error) {
    console.log(error)
  }

  return result
}

export default roundStats
