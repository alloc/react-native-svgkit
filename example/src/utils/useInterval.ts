import { useEffect, useRef } from 'react'

type Callback = () => void

export default function useInterval(callback: Callback, delay: number | null) {
  const savedCallback = useRef<Callback | null>(null)

  useEffect(() => {
    savedCallback.current = callback
  }, [callback])

  useEffect(() => {
    if (delay !== null) {
      const id = setInterval(() => savedCallback.current!(), delay)
      return () => clearInterval(id)
    }
  }, [delay])
}
