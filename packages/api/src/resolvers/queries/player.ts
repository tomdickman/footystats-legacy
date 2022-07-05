import { Context } from "../../context"

export type PlayerQueryArgs = {
  id: string
}

const player = async (_parent: any, { id }: PlayerQueryArgs, { db }: Context) => {
  let result

  try {
    const response = await db.query('SELECT * FROM player WHERE id = $1', [id])
    result = response.rows[0]
    // TODO: Move this into resolver so only resolves if 'roundstats' field is requested.
    const roundStats = await db.query('SELECT * FROM roundstats WHERE playerid = $1', [id])
    result.roundstats = roundStats.rows
  } catch(error) {
    console.log(error)
  }

  return result
}

export default player
