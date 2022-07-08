import type { NextPage } from 'next'
import Head from 'next/head'
import styles from '../styles/Home.module.css'

type HomeProps = {
  apiUrl: string
}

const Home: NextPage<HomeProps> = ({ apiUrl }) => {
  return (
    <div className={styles.container}>
      <Head>
        <title>AFL Footy Stats</title>
        <meta name="description" content="An AFL Fantasy statistics site" />
        <link rel="icon" href="/football_icon.ico" />
      </Head>

      <main className={styles.main}>
        <h1>AFL Footy Stats</h1>
        <p>Coming soon...</p>
      </main>

      <footer className={styles.footer}>
        <a
          href="https:tomdickman.com.au"
          target="_blank"
          rel="noopener noreferrer"
        >
          Built by Tom Dickman
        </a>
        <p style={{ "display": "none" }} >API URL: {apiUrl}</p>
      </footer>
    </div>
  )
}

export const getServerSideProps = async () => {
  return { props: { apiUrl: process.env.API_URL } }
};

export default Home
