// import { defaultAnimations, iOSExtraAnimations } from './animations'

export interface LoaderKitProps {
  name?: string,
  color?: string
  size?: number
}

declare const LoaderKit: (props: LoaderKitProps) => JSX.Element

export default LoaderKit