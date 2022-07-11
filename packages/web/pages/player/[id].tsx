import { GetStaticPaths, GetStaticProps, NextPage } from "next"
import { Player } from "../../models/Player"
import { RoundStats } from "../../models/RoundStats"


const Player: NextPage<Player> = ({ familyname, givenname, roundstats }) => {
  return (
    <>
      <h1>{givenname} {familyname}</h1>
      <ul>
        {roundstats.map(stats => {
          return (
            <li key={stats.game}>{stats.fantasypoints}</li>)
        })}
      </ul>
    </>
  )
}

export const getStaticPaths: GetStaticPaths = async () => {
  const res = await fetch(`${process.env.API_URL}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      "query": "query PlayersIds { players { id }}",
    })
  })

  const data: { id: string }[] = (await res.json()).data.players
  const paths = data.map(player => ({
    params: { id: player.id }
  }))

  return { paths, fallback: false }
}

export const getStaticProps: GetStaticProps = async ({ params }) => {
  const res = await fetch(`${process.env.API_URL}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      "query": "query($playerId: String!) { player(id: $playerId) { givenname familyname roundstats { fantasypoints } }}",
      "variables": {
        "playerId": params?.id
      }
    })
  })

  const respJson = await res.json()
  console.log(respJson)
  const data: { familyname: string, givenname: string, roundstats: RoundStats[] } = respJson.data.player
  console.log(data)

  return {
    props: {
      id: params?.id,
      familyname: data.familyname,
      givenname: data.givenname,
      roundstats: data.roundstats
    }
  }
}

export default Player
