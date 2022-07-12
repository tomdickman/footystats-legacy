import { gql } from "@apollo/client"
import { GetServerSideProps, NextPage } from "next"
import Error from "next/error"
import client from "../../apollo-client"

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
  let player = null

  try {
    const { data } = await client.query({
      query: gql`
        query($playerId: String!) {
          player(id: $playerId) {
            givenname
            familyname
            roundstats {
              fantasypoints
            }
          }
        }
      `,
      variables: {
        playerId: id
      }
    })
    player = data.player
  } catch(error) {
    console.log(JSON.stringify(error, null, 2))
  }


  return {
    props: {
      id,
      player,
      errorCode: (player !== null) ? false : "404"
    }
  }
}

export default PlayerPage
