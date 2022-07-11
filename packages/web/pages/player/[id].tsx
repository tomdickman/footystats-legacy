import { GetServerSideProps, NextPage } from "next"
import Error from "next/error"

import { Player } from "../../models/Player"
import { RoundStats } from "../../models/RoundStats"

type PlayerPageProps = {
  // Next has typed the error statusCode as `never` ¯\_(ツ)_/¯
  errorCode: never
  player: Player
}

const PlayerPage: NextPage<PlayerPageProps> = ({ player, errorCode }) => {
  if (errorCode) {
    return <Error statusCode={errorCode} />
  }

  return (
    <>
      <h1>{player.givenname} {player.familyname}</h1>
      <ul>
        {player.roundstats.map(stats => {
          return (
            <li key={stats.game}>{stats.fantasypoints}</li>)
        })}
      </ul>
    </>
  )
}

export const getServerSideProps: GetServerSideProps = async ({ query: { id } }) => {
  const res = await fetch(`${process.env.API_URL}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      "query": "query($playerId: String!) { player(id: $playerId) { givenname familyname roundstats { fantasypoints } }}",
      "variables": {
        "playerId": id
      }
    })
  })
  const respJson = await res.json()
  const player = respJson.data.player

  return {
    props: {
      id,
      player,
      errorCode: (player !== null) ? false : "404"
    }
  }
}

export default PlayerPage
